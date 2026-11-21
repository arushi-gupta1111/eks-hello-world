FROM python:3.12-alpine

WORKDIR /app

COPY app/main.py /app/main.py

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup

USER appuser

EXPOSE 8080

CMD ["python", "main.py"]
