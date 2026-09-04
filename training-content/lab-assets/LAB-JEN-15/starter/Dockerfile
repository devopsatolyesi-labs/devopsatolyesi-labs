FROM python:3.11-alpine
WORKDIR /app
RUN pip install --no-cache-dir flask
COPY app/ ./app/
EXPOSE 5000
CMD ["python", "app/main.py"]
