#!/bin/bash
source /home/gitlab-runner/telegram.env
STATUS="$1"
TEXT="Статус: ${STATUS}%0A%0AПроект: ${CI_PROJECT_NAME}%0AВетка: ${CI_COMMIT_REF_NAME}%0AКоммит: ${CI_COMMIT_TITLE}%0AХеш: ${CI_COMMIT_SHORT_SHA}%0ANомер: ${CI_PIPELINE_ID}%0AJob статус: ${CI_JOB_STATUS}"
curl -s --max-time 10 -d "chat_id=${TELEGRAM_USER_ID}&disable_web_page_preview=1&text=${TEXT}" "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" > /dev/null
