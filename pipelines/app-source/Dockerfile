FROM registry.redhat.io/ubi9/python-311:latest

WORKDIR /app
COPY app.py requirements.txt ./
EXPOSE 8080
CMD ["python", "app.py"]
