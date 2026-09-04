#!/usr/bin/env bash
set -euo pipefail

# TODO: Aşağıdaki yedekleme işlemlerini tamamlayın:
# 1. 'alpine:3.21' imajını 'alpine-backup.tar.gz' olarak sıkıştırarak kaydedin (docker save + gzip)
# 2. 'test-app' adında bir volume oluşturup içerisine 'backup-test.txt' dosyası yazın
# 3. Geçici bir alpine container ile 'test-app' volume içeriğini 'volume-backup.tar.gz' dosyasına yedekleyin
