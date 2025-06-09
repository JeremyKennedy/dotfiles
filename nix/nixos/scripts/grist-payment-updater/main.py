#!/usr/bin/env python3
"""
Grist Payment Date Updater

Updates payment dates in Grist based on recurrence patterns.
Advances dates to future if they're in the past.
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from typing import List, Dict, Any, Optional
import httpx
from dotenv import load_dotenv


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class GristPaymentUpdater:
    def __init__(self, dry_run=True):
        self.api_key = os.getenv('GRIST_API_KEY')
        self.proxy_auth = os.getenv('GRIST_PROXY_AUTH')
        self.base_url = "https://grist.jeremyk.net"
        self.doc_id = "iDEabeoAf4nC"
        self.table_name = "Data"
        self.dry_run = dry_run
        
        if not self.api_key:
            raise ValueError("GRIST_API_KEY environment variable is required")
        if not self.proxy_auth:
            raise ValueError("GRIST_PROXY_AUTH environment variable is required")
        
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Proxy-Authorization": self.proxy_auth
        }
    
    def get_tables(self) -> List[str]:
        """Get list of available tables."""
        url = f"{self.base_url}/api/docs/{self.doc_id}/tables"
        
        with httpx.Client() as client:
            response = client.get(url, headers=self.headers)
            response.raise_for_status()
            
        data = response.json()
        return [table['id'] for table in data.get('tables', [])]
    
    def get_records(self) -> List[Dict[str, Any]]:
        """Fetch all records from the Finances table."""
        url = f"{self.base_url}/api/docs/{self.doc_id}/tables/{self.table_name}/records"
        
        with httpx.Client() as client:
            response = client.get(url, headers=self.headers)
            response.raise_for_status()
            
        data = response.json()
        return data.get('records', [])
    
    def calculate_next_payment_date(self, current_date, recurrence: str):
        """Calculate the next payment date based on recurrence."""
        try:
            # Parse current date - handle both string and timestamp formats
            if isinstance(current_date, (int, float)):
                # Unix timestamp (seconds since epoch)
                date = datetime.fromtimestamp(current_date)
            elif isinstance(current_date, str):
                # String format
                date = datetime.strptime(current_date, '%Y-%m-%d')
            else:
                logger.warning(f"Unknown date format: {current_date}")
                return current_date
                
            today = datetime.now().date()
            
            # Keep advancing until date is in the future
            while date.date() <= today:
                if recurrence.lower() == 'yearly':
                    date += relativedelta(years=1)
                elif recurrence.lower() == 'monthly':
                    date += relativedelta(months=1)
                elif recurrence.lower() in ['two weeks', 'biweekly']:
                    date += timedelta(weeks=2)
                else:
                    logger.warning(f"Unknown recurrence type: {recurrence}")
                    return current_date
            
            # Return as timestamp if input was timestamp, string if input was string
            if isinstance(current_date, (int, float)):
                return int(date.timestamp())
            else:
                return date.strftime('%Y-%m-%d')
            
        except Exception as e:
            logger.error(f"Error calculating next payment date: {e}")
            return current_date
    
    def update_record(self, record_id: int, new_date) -> bool:
        """Update a single record with new payment date."""
        if self.dry_run:
            logger.info(f"DRY RUN: Would update record {record_id} with new date: {new_date}")
            return True
            
        url = f"{self.base_url}/api/docs/{self.doc_id}/tables/{self.table_name}/records"
        
        payload = {
            "records": [
                {
                    "id": record_id,
                    "fields": {
                        "Next_Payment": new_date
                    }
                }
            ]
        }
        
        try:
            with httpx.Client() as client:
                response = client.patch(url, headers=self.headers, json=payload)
                response.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"Error updating record {record_id}: {e}")
            return False
    
    def process_records(self):
        """Main processing function."""
        try:
            logger.info(f"Running in {'DRY RUN' if self.dry_run else 'LIVE'} mode")
            
            # First, list available tables
            tables = self.get_tables()
            logger.info(f"Available tables: {tables}")
            
            if self.table_name not in tables:
                logger.error(f"Table '{self.table_name}' not found. Available: {tables}")
                return
                
            records = self.get_records()
            logger.info(f"Found {len(records)} records")
            
            # First pass: analyze what we would change
            potential_updates = []
            
            for record in records:
                record_id = record['id']
                fields = record['fields']
                
                # Get current values
                current_payment_date = fields.get('Next_Payment')
                recurrence = fields.get('Recurrence')
                expense_name = fields.get('Expense', 'Unknown')
                
                if not current_payment_date or not recurrence:
                    logger.warning(f"Record {record_id} ({expense_name}) missing payment date or recurrence")
                    continue
                
                # Calculate new date
                new_date = self.calculate_next_payment_date(current_payment_date, recurrence)
                
                # Check if date would change
                if new_date != current_payment_date:
                    # Convert timestamp to readable format for logging
                    if isinstance(current_payment_date, (int, float)):
                        current_readable = datetime.fromtimestamp(current_payment_date).strftime('%Y-%m-%d')
                    else:
                        current_readable = current_payment_date
                        
                    if isinstance(new_date, (int, float)):
                        new_readable = datetime.fromtimestamp(new_date).strftime('%Y-%m-%d')
                    else:
                        new_readable = new_date
                    
                    potential_updates.append({
                        'id': record_id,
                        'current': current_payment_date,
                        'new': new_date,
                        'current_readable': current_readable,
                        'new_readable': new_readable,
                        'recurrence': recurrence,
                        'expense_name': expense_name
                    })
            
            if potential_updates:
                logger.info(f"Found {len(potential_updates)} records that need updating:")
                for update in potential_updates:
                    logger.info(f"  {update['expense_name']}: {update['current_readable']} -> {update['new_readable']} ({update['recurrence']})")
            else:
                logger.info("No records need updating")
            
            # Actually perform updates
            updated_count = 0
            for update in potential_updates:
                if self.update_record(update['id'], update['new']):
                    updated_count += 1
            
            logger.info(f"{'Would update' if self.dry_run else 'Updated'} {updated_count} records")
            
        except Exception as e:
            logger.error(f"Error processing records: {e}")
            sys.exit(1)


def main():
    """Main entry point."""
    try:
        # Load .env file if running standalone
        load_dotenv()
        
        # Default to dry run for safety
        dry_run = os.getenv('DRY_RUN', 'true').lower() != 'false'
        updater = GristPaymentUpdater(dry_run=dry_run)
        updater.process_records()
        logger.info("Payment date update completed successfully")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()