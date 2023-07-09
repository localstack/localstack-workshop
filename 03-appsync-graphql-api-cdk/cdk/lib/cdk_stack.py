from os import path

from aws_cdk import (
    Stack,
    SecretValue,
    aws_appsync as appsync,
    aws_dynamodb as dynamodb,
    aws_rds as rds,
    aws_secretsmanager as secretsmanager,
)
from constructs import Construct


class CdkStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # RDS Serverless Postgres DB cluster
        cluster = rds.ServerlessCluster(
            self,
            "Database",
            default_database_name="testappsync",
            engine=rds.DatabaseClusterEngine.aurora_postgres(
                version=rds.AuroraPostgresEngineVersion.VER_11_16
            ),
            credentials=rds.Credentials.from_username(
                "testuser",
                password=SecretValue.unsafe_plain_text("testpass"),
            ),
        )

        # DynamoDB table
        table = dynamodb.Table(
            self,
            "Table",
            table_name="table1",
            partition_key=dynamodb.Attribute(
                name="id", type=dynamodb.AttributeType.STRING
            ),
        )

        # GraphQL API
        api = appsync.GraphqlApi(
            self,
            "GraphqlApi",
            name="test-api",
            schema=appsync.SchemaFile.from_asset(_path("schema.graphql")),
        )

        # RDS data source
        secret = secretsmanager.Secret(
            self,
            "SecretRDS",
            secret_string_value=SecretValue.unsafe_plain_text("testpass"),
        )
        data_source_rds = api.add_rds_data_source(
            "DS_RDS", cluster, secret_store=secret, database_name="testappsync"
        )

        # resolver mapping for RDS "addPostRDS"
        data_source_rds.create_resolver(
            "RdsAddPost",
            type_name="Mutation",
            field_name="addPostRDS",
            request_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/rds.insert.request.vlt")
            ),
            response_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/rds.insert.response.vlt")
            ),
        )

        # resolver mapping for RDS "getPostsRDS"
        data_source_rds.create_resolver(
            "RdsGetPosts",
            type_name="Query",
            field_name="getPostsRDS",
            request_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/rds.select.request.vlt")
            ),
            response_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/rds.select.response.vlt")
            ),
        )

        # DynamoDB data source
        data_source_ddb = api.add_dynamo_db_data_source("DS_DynamoDB", table)

        # resolver mapping for DynamoDB "addPostRDS"
        data_source_ddb.create_resolver(
            "DdbAddPost",
            type_name="Mutation",
            field_name="addPostDDB",
            request_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/ddb.PutItem.request.vlt")
            ),
            response_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/ddb.PutItem.response.vlt")
            ),
        )

        # resolver mapping for RDS "getPostsRDS"
        data_source_ddb.create_resolver(
            "DdbGetPosts",
            type_name="Query",
            field_name="getPostsDDB",
            request_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/ddb.Scan.request.vlt")
            ),
            response_mapping_template=appsync.MappingTemplate.from_file(
                _path("templates/ddb.Scan.response.vlt")
            ),
        )


def _path(*args):
    root_path = path.join(path.dirname(__file__), "..", "..")
    return path.join(root_path, *args)
