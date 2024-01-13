import pandas as pd
import json
import boto3


S3_RESOURCE = boto3.resource("s3")
BUCKET = "test-nelson-igbokwe"
PREFIX = "aws_batch_source/"
OUTPUT_PREFIX = "aws_batch_output/"
S3_BUCKET = S3_RESOURCE.Bucket(BUCKET)

def main():
    keys = list_keys_s3(PREFIX)
    process_keys(keys)

def list_keys_s3(prefix: str) -> list:
    return [obj.key for obj in S3_BUCKET.objects.filter(Prefix=prefix) if obj.key.endswith(".json")]

def read_json_s3(bucket: str, key: str) -> dict:
    obj = S3_RESOURCE.Object(bucket, key)
    return json.loads(obj.get()["Body"].read().decode("utf-8"))

def transform_data(raw_data: dict) -> pd.DataFrame:
    data_df = pd.DataFrame(raw_data["data"])
    device_name = raw_data["metadata"]["device"]
    city = raw_data["metadata"]["city"]
    data_df["device"] = device_name
    data_df["city"] = city

    # Do transformation
    data_df["timestamp"] = pd.to_datetime(data_df["timestamp"])
    data_df.set_index("timestamp", inplace=True)
    data_df["mean_temp"] = data_df["temperature"].resample("D").mean()
    data_df.dropna(inplace=True)
    data_df.reset_index(inplace=True)
    data_df["timestamp"] = data_df["timestamp"].dt.tz_convert(None).dt.strftime("%Y-%m-%d")
    return data_df

def save_data_s3(df: pd.DataFrame, key: str) -> None:
    filename = key.split("/")[-1].replace(".json", ".xlsx")
    output_path = f"s3://{BUCKET}/{OUTPUT_PREFIX}{filename}"
    df.to_excel(output_path, index=False)


def process_keys(keys: list[str]) -> None:
    for key in keys:
        raw_data = read_json_s3(BUCKET, key)
        transform_data_df = transform_data(raw_data)
        save_data_s3(transform_data_df, key)

if __name__ == "__main__":
    main()
    