#!/usr/bin/env python3
from email.mime.text import MIMEText
from getpass import getuser
from smtplib import SMTP


def send_mail(to: str, subject: str, body: str, from_: str | None = None):
    msg = MIMEText(body, _charset="UTF-8")
    msg["From"], msg["To"], msg["Subject"] = (
        f"{getuser()}@localhost" if from_ is None else from_,
        to,
        subject,
    )
    with SMTP("localhost") as s:
        s.send_message(msg)


def parse_args():
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Send an email.")
    parser.add_argument(
        "--from",
        dest="from_",
        type=str,
        help="Email sender",
    )
    parser.add_argument(
        "--to", dest="to", type=str, required=True, help="Email recipient"
    )
    parser.add_argument(
        "--subject", dest="subject", type=str, required=True, help="Email subject"
    )
    parser.add_argument(
        "--body", dest="body", type=str, required=True, help="Email body"
    )
    args = parser.parse_args()
    return args


def main():
    args = parse_args()
    send_mail(from_=args.from_, to=args.to, subject=args.subject, body=args.body)


if __name__ == "__main__":
    main()
