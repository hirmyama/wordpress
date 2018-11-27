# ============================================================================
# CloudWatch統合エージェントのセットアップ
# EC2のロールに下記を追加
# AmazonEC2RoleforSSM
# AmazonEC2ReadOnlyAccess
# ============================================================================

curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
cat << 'EOF' | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 10,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "resources": [
          "*"
        ],
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_nice", "unit": "Percent"},
          "cpu_usage_guest"
        ],
        "totalcpu": false,
        "metrics_collection_interval": 10,
        "append_dimensions": {
          "customized_dimension_key_1": "customized_dimension_value_1",
          "customized_dimension_key_2": "customized_dimension_value_2"
        }
      },
      "disk": {
        "resources": [
          "/",
          "/tmp"
        ],
        "measurement": [
          {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},
          "total",
          "used"
        ],
         "ignore_file_system_types": [
          "sysfs", "devtmpfs"
        ],
        "metrics_collection_interval": 60,
        "append_dimensions": {
          "customized_dimension_key_3": "customized_dimension_value_3",
          "customized_dimension_key_4": "customized_dimension_value_4"
        }
      },
      "diskio": {
        "resources": [
          "*"
        ],
        "measurement": [
          "reads",
          "writes",
          "read_time",
          "write_time",
          "io_time"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used",
          "swap_free",
          "swap_used_percent"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used",
          "mem_cached",
          "mem_total"
        ],
        "metrics_collection_interval": 1
      },
      "net": {
        "resources": [
          "eth0"
        ],
        "measurement": [
          "bytes_sent",
          "bytes_recv",
          "drop_in",
          "drop_out"
        ]
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_syn_sent",
          "tcp_close"
        ],
        "metrics_collection_interval": 60
      },
      "processes": {
        "measurement": [
          "running",
          "sleeping",
          "dead"
        ]
      }
    },
    "append_dimensions": {
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}",
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}"
    },
    "aggregation_dimensions" : [["ImageId"], ["InstanceId", "InstanceType"], ["d1"],[]]
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "wordpress",
            "log_stream_name": "access_log",
            "timezone": "Local"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "wordpress",
            "log_stream_name": "error_log",
            "timezone": "Local"
          }
        ]
      }
    },
    "log_stream_name": "my_log_stream_name"
  }
}
EOF
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
