#!/bin/bash

DISK=("nvme1n1")

for disk in "${DISK[@]}"; do
    DISK_DIR="/dev/${disk}"
    PART="/dev/${disk}p1"

    if [ -e "${DISK_DIR}" ]; then

        if [ -e "${PART}" ]; then
            # 파티션이 존재하므로 마운트만 시행
            DISK_MNT_DIR="/mnt/${disk}/data"

            sudo mkdir -p "${DISK_MNT_DIR}"

            UUID1=$(sudo blkid -s UUID -o value "${PART}")

            echo "UUID=${UUID1}  ${DISK_MNT_DIR}  xfs  defaults,nofail  0  2" \
                | sudo tee -a /etc/fstab > /dev/null

            sudo systemctl daemon-reload
            sudo mount -a

        else
            # 파티션이 없으므로 파티션 생성
            echo -e "g\nn\n\n\n\nw\n" | sudo fdisk "${DISK_DIR}"

            sudo udevadm settle

            sudo mkfs -t xfs "${PART}"

            DISK_MNT_DIR="/mnt/${disk}/data"

            sudo mkdir -p "${DISK_MNT_DIR}"

            UUID1=$(sudo blkid -s UUID -o value "${PART}")

            echo "UUID=${UUID1}  ${DISK_MNT_DIR}  xfs  defaults,nofail  0  2" \
                | sudo tee -a /etc/fstab > /dev/null

            sudo systemctl daemon-reload
            sudo mount -a
        fi

    else
        echo "${DISK_DIR} 장치가 존재하지 않습니다."
    fi
done