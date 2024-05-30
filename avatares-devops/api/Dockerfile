FROM python:3.10

EXPOSE 5000

WORKDIR /api

COPY requirements.txt /api
RUN pip install -r requirements.txt

COPY . /api
CMD ["flask", "run", "--host", "0.0.0.0"]
