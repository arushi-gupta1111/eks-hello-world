FROM python:3.12-alpine

WORKDIR /app
COPY app/main.py /app/main.py

RUN adduser -D -u 10001 appuser
USER 1001

EXPOSE 8080
CMD ["python", "-u", "/app/main.py"]

