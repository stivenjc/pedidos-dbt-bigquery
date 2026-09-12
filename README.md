# pedidos-dbt-bigquery

Proyecto de transformación de datos con **dbt** sobre **BigQuery**, que modela los pedidos de 3 tiendas regionales (Norte, Centro, Sur) como un star schema analítico.

Este proyecto toma los datos crudos ya cargados en BigQuery (provenientes del [pipeline de pedidos con Airflow](#) — repositorio separado) y los transforma en un modelo dimensional listo para análisis, con tests automáticos de calidad de datos.

## Qué resuelve este proyecto

Los datos de pedidos llegan a BigQuery en una tabla cruda y plana (`pedidos_raw`): un pedido por fila, con el nombre del producto, la tienda y la fecha repetidos como texto en cada registro. Este proyecto transforma esa tabla en un **star schema**: una tabla de hechos con las métricas, y tres tablas de dimensiones que describen el contexto de cada pedido.

| Tabla | Tipo | Contenido |
|---|---|---|
| `hechos_pedidos` | Hechos | cantidad, precio_unitario + ids de cada dimensión |
| `dim_producto` | Dimensión | productos únicos, con su id |
| `dim_tienda` | Dimensión | tiendas únicas, con su id |
| `dim_fecha` | Dimensión | fechas únicas, con año, mes, trimestre, día de la semana y si es fin de semana |

## Arquitectura

```
BigQuery: pedidos_raw (tabla cruda, cargada desde Cloud Storage)
                    │
                    ▼
        dbt (modelos SQL versionados)
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
  dim_producto  dim_tienda   dim_fecha
        │           │           │
        └─────┬─────┴─────┬─────┘
              ▼           ▼
           hechos_pedidos (JOIN + ref())
```

Cada modelo es un archivo `.sql` con un `SELECT` — dbt se encarga de generar el `CREATE TABLE` y de correr los modelos en el orden correcto de dependencias (vía `ref()`).

## Stack técnico

- **dbt-bigquery** — transformación de datos, tests, documentación
- **BigQuery** — data warehouse
- **Cloud Storage** — zona de datos crudos (staging)
- **Airflow** (repositorio separado) — orquesta la ejecución diaria de `dbt run` y `dbt test`

## Estructura del proyecto

```
├── models/
│   ├── dim_producto.sql
│   ├── dim_tienda.sql
│   ├── dim_fecha.sql
│   ├── hechos_pedidos.sql
│   └── schema.yml          # definición de tests
├── seeds/                   # (sin uso por ahora)
├── tests/
├── macros/
├── dbt_project.yml
└── requirements.txt
```

## Tests de calidad de datos

Definidos en `models/schema.yml`:

- `unique` + `not_null` en el id de cada dimensión (`id_producto`, `id_tienda`, `id_fecha`).
- `relationships` en `hechos_pedidos`: valida que cada id foráneo exista realmente en su dimensión correspondiente (detecta si un `JOIN` perdió filas silenciosamente).

## Cómo correrlo

### 1. Preparar el entorno

```bash
python -m venv venv_dbt
source venv_dbt/bin/activate
pip install --only-binary=:all: dbt-bigquery
```

### 2. Autenticación con GCP

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project pedidos-dataeng
```

### 3. Correr los modelos

```bash
dbt run
```

### 4. Correr los tests

```bash
dbt test
```

## Decisiones de diseño

- **ELT, no ETL:** los datos se cargan crudos a BigQuery primero, y se transforman *dentro* del warehouse con SQL — no se procesan antes de cargarlos. Es el patrón estándar al trabajar con warehouses en la nube.
- **`ref()` entre modelos, nunca nombres de tabla hardcodeados:** permite que dbt resuelva automáticamente el orden de ejecución (su propio DAG de dependencias) y facilita portar el proyecto a otro entorno sin reescribir cada modelo.
- **Materialización `table` explícita:** los modelos se declaran como tablas físicas (no vistas), consistente con cómo se usaban antes de migrar a dbt.
- **Autenticación por impersonation de una cuenta de servicio, no claves JSON:** la organización de GCP bloquea la generación de claves descargables (política de seguridad estándar); se usa impersonation en su lugar, evitando cualquier archivo de credenciales que se pueda filtrar.

## Próximos pasos (no implementados aún)

- CI/CD con GitHub Actions: correr `dbt test` automáticamente en cada push.
- Orquestación diaria vía Airflow (ver repositorio del pipeline de pedidos).