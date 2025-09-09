# locustfile.py - Main Locust Load Testing File
from locust import User, task, between, events
import smtplib
import imaplib
import poplib
import ssl
import time
import random
import json
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from faker import Faker
import os
import csv
from datetime import datetime
import subprocess

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EmailServerConfig:
    """Email server configuration"""
    SMTP_SERVER = "aravindahwk.org"
    SMTP_PORT = 587
    IMAP_SERVER = "aravindahwk.org"
    IMAP_PORT = 143
    POP3_SERVER = "aravindahwk.org"
    POP3_PORT = 110
    USE_TLS = True
    TIMEOUT = 30

class TestDataGenerator:
    """Generate realistic test data for emails"""
    
    def __init__(self):
        self.fake = Faker()
        self.email_templates = self._load_templates()
        self.attachments = self._get_attachments()
    
    def _load_templates(self):
        """Load email templates"""
        return {
            'marketing': """
            <html><body>
            <h2>Special Offer Just for You!</h2>
            <p>Dear {name},</p>
            <p>We have an exclusive offer that expires soon...</p>
            <img src="cid:image1" alt="Promotion">
            </body></html>
            """,
            'transactional': """
            <html><body>
            <h2>Order Confirmation</h2>
            <p>Dear {name},</p>
            <p>Your order #{order_id} has been confirmed.</p>
            <p>Total: ${amount}</p>
            </body></html>
            """,
            'newsletter': """
            <html><body>
            <h1>Weekly Newsletter</h1>
            <p>Hello {name},</p>
            <p>Here are this week's highlights...</p>
            <ul>
                <li>Feature update</li>
                <li>New blog post</li>
                <li>Community spotlight</li>
            </ul>
            </body></html>
            """,
            'plain_text': """
            Hi {name},
            
            This is a simple text message for testing purposes.
            
            Regards,
            Test System
            """
        }
    
    def _get_attachments(self):
        """Get list of test attachment files"""
        attachment_dir = "test_data/attachments/"
        if not os.path.exists(attachment_dir):
            os.makedirs(attachment_dir)
            # Create sample files
            self._create_sample_attachments(attachment_dir)
        
        return [
            {"path": f"{attachment_dir}sample.pdf", "size": "1MB"},
            {"path": f"{attachment_dir}image.jpg", "size": "500KB"},
            {"path": f"{attachment_dir}document.docx", "size": "2MB"},
            {"path": f"{attachment_dir}spreadsheet.xlsx", "size": "3MB"},
            {"path": f"{attachment_dir}large_file.zip", "size": "10MB"}
        ]
    
    def _create_sample_attachments(self, directory):
        """Create sample attachment files for testing"""
        # Create files of different sizes
        sizes = {
            "sample.pdf": 1024 * 1024,      # 1MB
            "image.jpg": 512 * 1024,        # 500KB
            "document.docx": 2 * 1024 * 1024, # 2MB
            "spreadsheet.xlsx": 3 * 1024 * 1024, # 3MB
            "large_file.zip": 10 * 1024 * 1024  # 10MB
        }
        
        for filename, size in sizes.items():
            filepath = os.path.join(directory, filename)
            with open(filepath, 'wb') as f:
                f.write(b'0' * size)
    
    def generate_email_content(self, email_type="random"):
        """Generate email content based on type"""
        if email_type == "random":
            email_type = random.choice(list(self.email_templates.keys()))
        
        template = self.email_templates[email_type]
        
        return {
            'subject': self.fake.sentence(nb_words=6),
            'body': template.format(
                name=self.fake.name(),
                order_id=random.randint(10000, 99999),
                amount=random.uniform(10.99, 299.99)
            ),
            'type': email_type
        }
    
    def get_random_attachment(self):
        """Get a random attachment for testing"""
        return random.choice(self.attachments)

class TestUserManager:
    """Manage test user accounts"""
    
    def __init__(self, users_file="test_data/users.csv"):
        self.users_file = users_file
        self.users = self._load_users()
    
    def _load_users(self):
        """Load test users from CSV file"""
        users = []
        if os.path.exists(self.users_file):
            with open(self.users_file, 'r') as f:
                reader = csv.DictReader(f)
                users = list(reader)
        else:
            # Create sample users if file doesn't exist
            users = self._create_sample_users()
            self._save_users(users)
        
        return users
    
    def _create_sample_users(self):
        """Create sample test users"""
        fake = Faker()
        users = []
        for i in range(100):
            users.append({
                'username': f'testuser{i:03d}',
                'email': f'testuser{i:03d}@aravindahwk.org',
                'password': 'TestPassword123!',
                'full_name': fake.name()
            })
        return users
    
    def _save_users(self, users):
        """Save users to CSV file"""
        os.makedirs(os.path.dirname(self.users_file), exist_ok=True)
        with open(self.users_file, 'w', newline='') as f:
            if users:
                writer = csv.DictWriter(f, fieldnames=users[0].keys())
                writer.writeheader()
                writer.writerows(users)
    
    def get_random_user(self):
        """Get a random test user"""
        return random.choice(self.users)

class SMTPLoadTester(User):
    """SMTP Load Testing User"""
    wait_time = between(1, 5)
    weight = 3
    
    def on_start(self):
        """Initialize user session"""
        self.config = EmailServerConfig()
        self.data_generator = TestDataGenerator()
        self.user_manager = TestUserManager()
        self.user_account = self.user_manager.get_random_user()
        logger.info(f"Starting SMTP tests for user: {self.user_account['email']}")
    
    def _connect_smtp(self):
        """Establish SMTP connection"""
        try:
            start_time = time.time()
            
            if self.config.USE_TLS:
                server = smtplib.SMTP(self.config.SMTP_SERVER, self.config.SMTP_PORT)
                server.starttls()
            else:
                server = smtplib.SMTP(self.config.SMTP_SERVER, self.config.SMTP_PORT)
            
            server.login(self.user_account['username'], self.user_account['password'])
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="SMTP",
                name="connect",
                response_time=response_time,
                response_length=0
            )
            return server
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="SMTP",
                name="connect",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            return None
    
    @task(5)
    def send_plain_text_email(self):
        """Send plain text email"""
        server = self._connect_smtp()
        if not server:
            return
        
        try:
            start_time = time.time()
            
            content = self.data_generator.generate_email_content("plain_text")
            recipient = self.user_manager.get_random_user()['email']
            
            msg = MIMEText(content['body'], 'plain')
            msg['Subject'] = content['subject']
            msg['From'] = self.user_account['email']
            msg['To'] = recipient
            
            server.send_message(msg)
            server.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="SMTP",
                name="send_text",
                response_time=response_time,
                response_length=len(content['body'])
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="SMTP",
                name="send_text",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if server:
                server.quit()
    
    @task(3)
    def send_html_email(self):
        """Send HTML email"""
        server = self._connect_smtp()
        if not server:
            return
        
        try:
            start_time = time.time()
            
            content = self.data_generator.generate_email_content("marketing")
            recipient = self.user_manager.get_random_user()['email']
            
            msg = MIMEMultipart('alternative')
            msg['Subject'] = content['subject']
            msg['From'] = self.user_account['email']
            msg['To'] = recipient
            
            html_part = MIMEText(content['body'], 'html')
            msg.attach(html_part)
            
            server.send_message(msg)
            server.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="SMTP",
                name="send_html",
                response_time=response_time,
                response_length=len(content['body'])
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="SMTP",
                name="send_html",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if server:
                server.quit()
    
    @task(1)
    def send_email_with_attachment(self):
        """Send email with attachment"""
        server = self._connect_smtp()
        if not server:
            return
        
        try:
            start_time = time.time()
            
            content = self.data_generator.generate_email_content("transactional")
            recipient = self.user_manager.get_random_user()['email']
            attachment = self.data_generator.get_random_attachment()
            
            msg = MIMEMultipart()
            msg['Subject'] = content['subject']
            msg['From'] = self.user_account['email']
            msg['To'] = recipient
            
            # Add body
            msg.attach(MIMEText(content['body'], 'html'))
            
            # Add attachment
            if os.path.exists(attachment['path']):
                with open(attachment['path'], "rb") as attachment_file:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment_file.read())
                
                encoders.encode_base64(part)
                part.add_header(
                    'Content-Disposition',
                    f'attachment; filename= {os.path.basename(attachment["path"])}'
                )
                msg.attach(part)
            
            server.send_message(msg)
            server.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="SMTP",
                name="send_attachment",
                response_time=response_time,
                response_length=len(content['body'])
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="SMTP",
                name="send_attachment",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if server:
                server.quit()
    
    @task(2)
    def send_bulk_emails(self):
        """Send multiple emails in one session"""
        server = self._connect_smtp()
        if not server:
            return
        
        try:
            start_time = time.time()
            
            # Send 5-10 emails in one session
            num_emails = random.randint(5, 10)
            
            for i in range(num_emails):
                content = self.data_generator.generate_email_content()
                recipient = self.user_manager.get_random_user()['email']
                
                msg = MIMEText(content['body'], 'plain' if content['type'] == 'plain_text' else 'html')
                msg['Subject'] = f"Bulk Test {i+1}: {content['subject']}"
                msg['From'] = self.user_account['email']
                msg['To'] = recipient
                
                server.send_message(msg)
            
            server.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="SMTP",
                name="send_bulk",
                response_time=response_time,
                response_length=num_emails
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="SMTP",
                name="send_bulk",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if server:
                server.quit()

class IMAPLoadTester(User):
    """IMAP Load Testing User"""
    wait_time = between(2, 8)
    weight = 2
    
    def on_start(self):
        """Initialize IMAP user session"""
        self.config = EmailServerConfig()
        self.user_manager = TestUserManager()
        self.user_account = self.user_manager.get_random_user()
        logger.info(f"Starting IMAP tests for user: {self.user_account['email']}")
    
    def _connect_imap(self):
        """Establish IMAP connection"""
        try:
            start_time = time.time()
            
            if self.config.USE_TLS:
                mail = imaplib.IMAP4_SSL(self.config.IMAP_SERVER, self.config.IMAP_PORT)
            else:
                mail = imaplib.IMAP4(self.config.IMAP_SERVER, self.config.IMAP_PORT)
            
            mail.login(self.user_account['username'], self.user_account['password'])
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="IMAP",
                name="connect",
                response_time=response_time,
                response_length=0
            )
            return mail
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="IMAP",
                name="connect",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            return None
    
    @task(3)
    def list_folders(self):
        """List mail folders"""
        mail = self._connect_imap()
        if not mail:
            return
        
        try:
            start_time = time.time()
            
            status, folders = mail.list()
            mail.logout()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="IMAP",
                name="list_folders",
                response_time=response_time,
                response_length=len(folders) if folders else 0
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="IMAP",
                name="list_folders",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if mail:
                mail.logout()
    
    @task(4)
    def check_inbox(self):
        """Check inbox messages"""
        mail = self._connect_imap()
        if not mail:
            return
        
        try:
            start_time = time.time()
            
            mail.select('INBOX')
            status, messages = mail.search(None, 'ALL')
            
            if messages[0]:
                message_count = len(messages[0].split())
            else:
                message_count = 0
            
            mail.logout()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="IMAP",
                name="check_inbox",
                response_time=response_time,
                response_length=message_count
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="IMAP",
                name="check_inbox",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if mail:
                mail.logout()
    
    @task(2)
    def fetch_recent_messages(self):
        """Fetch recent messages"""
        mail = self._connect_imap()
        if not mail:
            return
        
        try:
            start_time = time.time()
            
            mail.select('INBOX')
            status, messages = mail.search(None, 'RECENT')
            
            # Fetch up to 5 recent messages
            if messages[0]:
                message_ids = messages[0].split()
                fetch_count = min(5, len(message_ids))
                
                for msg_id in message_ids[-fetch_count:]:
                    status, msg_data = mail.fetch(msg_id, '(RFC822)')
            
            mail.logout()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="IMAP",
                name="fetch_messages",
                response_time=response_time,
                response_length=fetch_count if messages[0] else 0
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="IMAP",
                name="fetch_messages",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if mail:
                mail.logout()

class POP3LoadTester(User):
    """POP3 Load Testing User"""
    wait_time = between(3, 10)
    weight = 1
    
    def on_start(self):
        """Initialize POP3 user session"""
        self.config = EmailServerConfig()
        self.user_manager = TestUserManager()
        self.user_account = self.user_manager.get_random_user()
        logger.info(f"Starting POP3 tests for user: {self.user_account['email']}")
    
    def _connect_pop3(self):
        """Establish POP3 connection"""
        try:
            start_time = time.time()
            
            if self.config.USE_TLS:
                mail = poplib.POP3_SSL(self.config.POP3_SERVER, self.config.POP3_PORT)
            else:
                mail = poplib.POP3(self.config.POP3_SERVER, self.config.POP3_PORT)
            
            mail.user(self.user_account['username'])
            mail.pass_(self.user_account['password'])
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="POP3",
                name="connect",
                response_time=response_time,
                response_length=0
            )
            return mail
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="POP3",
                name="connect",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            return None
    
    @task(3)
    def check_messages(self):
        """Check message count"""
        mail = self._connect_pop3()
        if not mail:
            return
        
        try:
            start_time = time.time()
            
            message_count, mailbox_size = mail.stat()
            mail.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="POP3",
                name="stat",
                response_time=response_time,
                response_length=message_count
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="POP3",
                name="stat",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if mail:
                mail.quit()
    
    @task(2)
    def retrieve_messages(self):
        """Retrieve messages"""
        mail = self._connect_pop3()
        if not mail:
            return
        
        try:
            start_time = time.time()
            
            message_count, mailbox_size = mail.stat()
            
            # Retrieve up to 3 messages
            retrieve_count = min(3, message_count)
            
            for i in range(1, retrieve_count + 1):
                response, lines, octets = mail.retr(i)
            
            mail.quit()
            
            response_time = (time.time() - start_time) * 1000
            events.request_success.fire(
                request_type="POP3",
                name="retrieve",
                response_time=response_time,
                response_length=retrieve_count
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            events.request_failure.fire(
                request_type="POP3",
                name="retrieve",
                response_time=response_time,
                response_length=0,
                exception=e
            )
            if mail:
                mail.quit()

# Event listeners for custom metrics
@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when test starts"""
    print("Email load testing started!")
    
    # Create necessary directories
    os.makedirs("test_data/attachments", exist_ok=True)
    os.makedirs("test_results", exist_ok=True)

@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when test stops"""
    print("Email load testing completed!")
    
    # Generate test report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = f"test_results/email_load_test_report_{timestamp}.json"
    
    # Save test statistics
    stats = environment.stats
    report_data = {
        "timestamp": timestamp,
        "total_requests": stats.total.num_requests,
        "total_failures": stats.total.num_failures,
        "average_response_time": stats.total.avg_response_time,
        "min_response_time": stats.total.min_response_time,
        "max_response_time": stats.total.max_response_time,
        "requests_per_second": stats.total.current_rps,
        "failure_rate": stats.total.fail_ratio
    }
    
    with open(report_file, 'w') as f:
        json.dump(report_data, f, indent=2)
    
    print(f"Test report saved to: {report_file}")

if __name__ == "__main__":
    # This allows running the test directly with python
    import sys
    os.system(f"locust -f {sys.argv[0]} --host=http://localhost")