"""Service testing with async HTTP requests."""

import re
import time
from dataclasses import dataclass
from typing import Dict, List, Optional
import httpx
from .traefik import TraefikService


@dataclass
class ServiceTestResult:
    """Result of testing a single service."""

    service_name: str
    url: str
    routing_type: str
    status_code: Optional[int] = None
    response_size: int = 0
    response_time: float = 0.0
    redirect_count: int = 0
    success: bool = False
    error_message: str = ""
    error_detail: str = ""


class ServiceTester:
    """Async service testing with detailed response analysis."""

    def __init__(self, timeout: float = 5.0, follow_redirects: bool = True):
        """Initialize service tester.

        Args:
            timeout: Request timeout in seconds
            follow_redirects: Whether to follow HTTP redirects
        """
        self.timeout = timeout
        self.follow_redirects = follow_redirects

    async def test_service(self, service: TraefikService) -> ServiceTestResult:
        """Test a single service for availability and response.

        This method replicates the bash script's detailed service testing logic.

        Args:
            service: TraefikService to test

        Returns:
            ServiceTestResult with detailed metrics
        """
        # Build the test URL with custom path if provided
        test_url = service.frontend_domain
        if service.custom_path:
            test_url = service.frontend_domain.rstrip('/') + service.custom_path
            
        result = ServiceTestResult(
            service_name=service.name,
            url=test_url,
            routing_type=service.routing_type,
        )

        try:
            start_time = time.time()

            async with httpx.AsyncClient(
                timeout=self.timeout,
                follow_redirects=self.follow_redirects,
                verify=False,  # Skip SSL verification like curl -k
            ) as client:
                response = await client.get(test_url)

                result.response_time = time.time() - start_time
                result.status_code = response.status_code
                result.response_size = len(response.content)
                result.redirect_count = len(response.history)

                # Analyze response for detailed error information
                result.error_detail = self._analyze_response(response)

                if 200 <= result.status_code < 400:
                    result.success = True
                else:
                    result.success = False
                    result.error_message = f"HTTP {result.status_code}"

        except httpx.TimeoutException:
            result.error_message = "Connection timeout"
            result.error_detail = "Request exceeded timeout limit"
        except httpx.ConnectError:
            result.error_message = "Connection refused"
            result.error_detail = "Could not connect to service"
        except httpx.HTTPStatusError as e:
            result.status_code = e.response.status_code
            result.error_message = f"HTTP {e.response.status_code}"
            result.error_detail = self._analyze_response(e.response)
        except Exception as e:
            result.error_message = "Unexpected error"
            result.error_detail = str(e)

        return result

    async def test_services(
        self, services: List[TraefikService]
    ) -> List[ServiceTestResult]:
        """Test multiple services concurrently.

        Args:
            services: List of TraefikService objects to test

        Returns:
            List of ServiceTestResult objects
        """
        import asyncio

        # Test all services concurrently for better performance
        tasks = [self.test_service(service) for service in services]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Handle any exceptions in concurrent execution
        valid_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                # Create error result for failed test
                error_result = ServiceTestResult(
                    service_name=services[i].name,
                    url=services[i].frontend_domain,
                    routing_type=services[i].routing_type,
                    error_message="Test execution failed",
                    error_detail=str(result),
                )
                valid_results.append(error_result)
            else:
                valid_results.append(result)

        return valid_results

    def _analyze_response(self, response: httpx.Response) -> str:
        """Extract detailed error information from HTTP response.

        This replicates the bash script's detailed error analysis logic.

        Args:
            response: HTTP response object

        Returns:
            Detailed error description
        """
        response_text = response.text

        # Check for common error patterns
        if "plain HTTP request was sent to HTTPS port" in response_text:
            return "(HTTPS/HTTP protocol mismatch - Traefik config issue)"
        elif any(
            pattern in response_text.lower() for pattern in ["bad gateway", "502"]
        ):
            return "(Bad Gateway - backend service unavailable)"
        elif any(pattern in response_text.lower() for pattern in ["404", "not found"]):
            return "(Not Found - service not configured or offline)"
        elif any(
            pattern in response_text.lower() for pattern in ["400", "bad request"]
        ):
            return "(Bad Request - invalid configuration)"
        elif any(
            pattern in response_text.lower()
            for pattern in ["503", "service unavailable"]
        ):
            return "(Service Unavailable - backend down)"
        elif "connection refused" in response_text.lower():
            return "(Connection refused - backend not responding)"
        elif "timeout" in response_text.lower():
            return "(Timeout - backend too slow)"
        elif len(response_text) < 50 and re.match(r"^\d+$", response_text.strip()):
            return "(Raw status code - minimal response)"
        elif len(response_text) > 0:
            # Show first 100 chars of error response for debugging
            error_snippet = response_text.replace("\n", " ")[:100]
            return f"(Error: {error_snippet}...)"
        else:
            return "(No response body)"


class ServiceTestReporter:
    """Generate reports from service test results."""

    def __init__(self):
        """Initialize reporter."""
        pass

    def categorize_results(
        self, results: List[ServiceTestResult]
    ) -> Dict[str, List[ServiceTestResult]]:
        """Categorize test results by routing type and status.

        Args:
            results: List of test results

        Returns:
            Dictionary categorizing results by type
        """
        categories = {
            "working": [r for r in results if r.success],
            "failed": [
                r
                for r in results
                if not r.success and r.error_message != "Connection timeout"
            ],
            "timeout": [r for r in results if r.error_message == "Connection timeout"],
            "direct": [r for r in results if r.routing_type == "Direct"],
            "swag": [r for r in results if r.routing_type == "SWAG"],
            "infrastructure": [
                r for r in results if r.routing_type == "Infrastructure"
            ],
        }
        return categories

    def calculate_health_score(self, results: List[ServiceTestResult]) -> int:
        """Calculate overall health score as percentage.

        Args:
            results: List of test results

        Returns:
            Health score percentage (0-100)
        """
        if not results:
            return 0

        working_count = sum(1 for r in results if r.success)
        return int((working_count * 100) / len(results))

    def generate_summary(self, results: List[ServiceTestResult]) -> Dict[str, any]:
        """Generate summary statistics from test results.

        Args:
            results: List of test results

        Returns:
            Summary dictionary with counts and health metrics
        """
        categories = self.categorize_results(results)
        health_score = self.calculate_health_score(results)

        return {
            "total_tests": len(results),
            "working_count": len(categories["working"]),
            "failed_count": len(categories["failed"]),
            "timeout_count": len(categories["timeout"]),
            "direct_count": len(categories["direct"]),
            "swag_count": len(categories["swag"]),
            "infrastructure_count": len(categories["infrastructure"]),
            "health_score": health_score,
            "categories": categories,
        }
