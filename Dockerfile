FROM python:3.9-alpine3.13
# LABEL maintainer="khawar shahzad"

# Ensures Python logs (stdout/stderr) are output immediately 
# (no buffering) — useful for logging inside Docker.
ENV PYTHONUNBUFFERED=1

COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
#COPY ./scripts /scripts
COPY ./app /app
WORKDIR /app

# Tells Docker that the app listens on port 8000 — standard for Django dev server.
EXPOSE 8000

ARG DEV=false

# Creates a virtual environment at /py and upgrades pip.
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    # postgresql-client → For connecting to psycopg2
    # jpeg-dev → Required for image processing libs like Pillow
    apk add --update --no-cache postgresql-client jpeg-dev && \
    # build-base → C compiler, make, etc.
    # postgresql-dev, musl-dev → headers to compile PostgreSQL libs
    # zlib → for image/compression libraries
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    # This removes the not required packages,
    # Which only were required to install pstgresql
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user && \
    # Create Media/Static Volumes
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol && \
    chmod -R 755 /vol
    # chmod -R +x /scripts

ENV PATH="/py/bin:$PATH"
# ENV PATH="/scripts:/py/bin:$PATH"

USER django-user

#CMD ["run.sh"]