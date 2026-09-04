FROM python:3.11-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
RUN useradd --uid 10001 appuser
USER 10001
EXPOSE 8080
CMD ["python", "main.py"]
