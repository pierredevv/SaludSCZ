# Estadísticas Generales y Protocolo de Validación Geográfica (SaludSCZ)

Este documento establece el marco de referencia geográfico, las estadísticas demográficas y el protocolo de validación estructural para el sistema de mapeo epidemiológico de Santa Cruz de la Sierra, Bolivia (SaludSCZ). Su objetivo es garantizar la integridad del análisis geoespacial de casos y recursos sanitarios mediante reglas estrictas de concordancia y validación.

---

## 📊 1. Estadísticas Generales

El sistema de SaludSCZ cubre el área urbana y de expansión inmediata de Santa Cruz de la Sierra, estructurada sobre una jerarquía de Distritos Municipales (DMs) oficiales y niveles de resolución asistencial.

### 👥 1.1. Distribución Demográfica por Distritos Municipales (DMs)
La población total considerada bajo cobertura activa en la plataforma de mapeo es de **1,848,000 habitantes**. Esta población está distribuida de manera excluyente y matemática en 16 Distritos Municipales (DM1 - Piraí, DM2 - Norte Interno, DM3 - Estación Argentina, DM4 - El Pari, DM5 - Norte, DM6 - Pampa de la Isla / El Dorado, DM7 - Villa 1ro de Mayo, DM8 - Plan 3000, DM9 - Palmasola / Sur, DM10 - El Bajío, DM11 - Centro, DM12 - Nuevo Palmar / El Palmar del Oratorio, DM U/R 13 - Distrito Urbano/Rural - El Palmar, DI - Distrito Industrial, DM14 - Área Urbana Paurito, DM15 - Área Urbana Montero Hoyos).

A continuación se detalla la distribución demográfica de los distritos municipales autorizados:

| Código Distrito | Distrito Municipal (Nombre Oficial / Zona) | Población Asignada |
| :--- | :--- | :--- |
| **DM1** | Piraí | 112,000 habs |
| **DM2** | Norte Interno | 83,000 habs |
| **DM3** | Estación Argentina | 85,000 habs |
| **DM4** | El Pari | 74,000 habs |
| **DM5** | Norte | 130,000 habs |
| **DM6** | Pampa de la Isla / El Dorado | 240,000 habs |
| **DM7** | Villa 1ro de Mayo | 245,000 habs |
| **DM8** | Plan 3000 | 315,000 habs |
| **DM9** | Palmasola / Sur | 150,000 habs |
| **DM10** | El Bajío | 120,000 habs |
| **DM11** | Centro | 60,000 habs |
| **DM12** | Nuevo Palmar / El Palmar del Oratorio | 115,000 habs |
| **DM U/R 13**| Distrito Urbano/Rural - El Palmar | 45,000 habs |
| **DI** | Distrito Industrial | 10,000 habs |
| **DM14** | Área Urbana Paurito | 35,000 habs |
| **DM15** | Área Urbana Montero Hoyos | 29,000 habs |
| **TOTAL** | **Área Urbana Validada** | **1,848,000 habs** |

---

### 🏥 1.2. Red de Centros de Salud de Referencia
Para el seguimiento de eventos de salud, se identifican 12 establecimientos de salud (INSTITUTO ONCOLOGICO DEL ORIENTE BOLIVIANO, H. JAPONES, HOSPITAL MATERNOLOGICO PERCY BOLAND, HOSPITAL DE NIÑOS "MARIO ORTIZ", HOSP. MUN. FRANCÉS, HOSPITAL MUNICIPAL. BAJIO DEL ORIENTE, CAJA NACIONAL DE SALUD "EL BAJIO", HOSITAL MUNICIPAL PLAN 3000, HOSPITAL MUNICIPAL VILLA 1RO DE MAYO, CLINICA ANGEL FOIANINI, CLINICA INCOR, CLINICA LAS AMERICAS CIRUGIA PLASTICAS), clasificados estrictamente según su nivel de resolución y estructura de administración:

#### A. Establecimientos de Tercer y Cuarto Nivel (4 centros de salud)
Hospitales de alta complejidad gestionados por el **Servicio Departamental de Salud (SEDES)** del Gobierno Autónomo Departamental de Santa Cruz o de referencia nacional:
1. **INSTITUTO ONCOLOGICO DEL ORIENTE BOLIVIANO**: Hospital de 4to Nivel especializado en oncología.
2. **H. JAPONES**: Hospital de 3er Nivel general con especialidades y terapia intensiva de referencia.
3. **HOSPITAL MATERNOLOGICO PERCY BOLAND**: Hospital de 3er Nivel especializado en gineco-obstetricia y neonatología.
4. **HOSPITAL DE NIÑOS "MARIO ORTIZ"**: Hospital de 3er Nivel pediátrico de referencia departamental.

#### B. Establecimientos de Segundo Nivel (4 centros de salud)
Hospitales generales administrados por el **Gobierno Autónomo Municipal de Santa Cruz de la Sierra** que ofrecen especialidades médicas básicas:
1. **HOSP. MUN. FRANCÉS**: Segundo nivel para la Red de Salud Sur (DM9).
2. **HOSPITAL MUNICIPAL. BAJIO DEL ORIENTE**: Segundo nivel para la Red de Salud Suroeste (DM10).
3. **HOSITAL MUNICIPAL PLAN 3000**: Segundo nivel para la Red de Salud Sureste (DM8).
4. **HOSPITAL MUNICIPAL VILLA 1RO DE MAYO**: Segundo nivel para la Red de Salud Este (DM7).

#### C. Clínicas Privadas (3 centros de salud)
Establecimientos de carácter privado y medicina prepagada con reporte epidemiológico obligatorio al sistema nacional de vigilancia:
1. **CLINICA ANGEL FOIANINI**: Centro privado de alta complejidad (DM11).
2. **CLINICA INCOR**: Centro privado especializado con foco en cardiología y cirugía (DM1).
3. **CLINICA LAS AMERICAS CIRUGIA PLASTICAS**: Centro privado especializado en cirugía plástica y reconstructiva (DM4).

#### D. Policonsultorios de Seguridad Social (1 centro de salud)
Centros médicos de atención ambulatoria especial y de corto plazo administrados por entes gestores:
1. **CAJA NACIONAL DE SALUD "EL BAJIO"**: Policonsultorio de atención ambulatoria y medicina familiar para asegurados en el distrito oeste (DM10).

---

## ✅ 2. Protocolo de Validación Geográfica y Estructural

Para evitar inconsistencias en el almacenamiento y despliegue cartográfico en la base de datos y la interfaz del usuario, el sistema SaludSCZ aplica reglas de validación en tiempo real.

### 🗺️ 2.1. Definición del Bounding Box (BBOX) de Validación
Cualquier coordenada (vértice de polígono o punto de ubicación de establecimiento) almacenada bajo el sistema de referencia espacial **WGS84** (EPSG:4326) debe encontrarse estrictamente dentro del Bounding Box geográfico del municipio de Santa Cruz de la Sierra (incluyendo sus distritos rurales de expansión DM14 y DM15):

*   **Longitud (X)**: `[-63.350000 a -62.750000]` (Límite Oeste a Límite Este)
*   **Latitud (Y)**: `[-17.950000 a -17.580000]` (Límite Sur a Límite Norte)

```mermaid
rect -63.35 -17.95 -62.75 -17.58
graph TD
    subgraph Bounding Box SCZ (WGS84)
        NorteLimits["Latitud Máxima: -17.580000 (Norte - Montero Hoyos)"]
        SurLimits["Latitud Mínima: -17.950000 (Sur - Palmasola)"]
        OesteLimits["Longitud Mínima: -63.350000 (Oeste - Piraí)"]
        EsteLimits["Longitud Máxima: -62.750000 (Este - Paurito)"]
    end
```

### 🔍 2.2. Validación y Cruce de Fuentes (OSM vs. SEDES)
1.  **Límites Urbanos y Catastro (OSM - OpenStreetMap)**: Se utiliza la base cartográfica de OpenStreetMap para validar la correspondencia espacial de barrios, radiales, anillos e infraestructuras viales. Se descarga el extracto municipal y se compara geométricamente mediante consultas de contención espacial (`ST_Contains`).
2.  **Registro de Establecimientos (SEDES)**: La nomenclatura del nombre de los centros y la codificación única del establecimiento deben contrastarse obligatoriamente con el registro oficial del SEDES. No se permite dar de alta un centro en el mapa si su código ministerial no ha sido validado.

---

### 🌐 2.3. Estructura y Esquema de Validación GeoJSON
Para que un archivo GeoJSON sea aceptado por la plataforma SaludSCZ, debe cumplir de forma obligatoria con las siguientes especificaciones estructurales basadas en el estándar RFC 7946:

1.  **Orden de las Coordenadas**: Siempre se especifica en formato `[Longitud, Latitud]` (`[X, Y]`).
2.  **Orientación de Polígonos**: Los polígonos deben cumplir la regla de la mano derecha (los vértices externos del polígono en sentido antihorario, los huecos internos en sentido horario).
3.  **Schema de Validación**:
    ```json
    {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "title": "GeoJSON FeatureCollection SaludSCZ",
      "type": "object",
      "required": ["type", "features"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["FeatureCollection"]
        },
        "features": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["type", "geometry", "properties"],
            "properties": {
              "type": {
                "type": "string",
                "enum": ["Feature"]
              },
              "geometry": {
                "type": "object",
                "required": ["type", "coordinates"],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": ["Point", "Polygon", "MultiPolygon"]
                  },
                  "coordinates": {
                    "type": "array"
                  }
                }
              },
              "properties": {
                "type": {
                  "type": "object",
                  "required": ["SISTEMA", "NOMBRE", "NIVEL", "DISTRITO", "ZONA_ASOCIADA"]
                }
              }
            }
          }
        }
      }
    }
    ```

---

### 💾 2.4. Ejemplo de Renderizado GeoJSON Válido
El siguiente conjunto de datos representa puntos de interés médico validados espacialmente dentro de los límites del BBOX `[-63.35, -17.95, -62.75, -17.58]` en formato GeoJSON RFC 7946 estándar con la estructura oficial del sistema de salud de la alcaldía:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.194165, -17.762952] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "INSTITUTO ONCOLOGICO DEL ORIENTE BOLIVIANO",
        "NIVEL": "HOSPITAL 4TO NIVEL",
        "DISTRITO": 1,
        "ZONA_ASOCIADA": "DM1 - Pirai",
        "UV": "ET21",
        "MZ": "",
        "BARRIO": "",
        "DIRECCION": "SOBRE TERCER ANILLO INTERNO Y EXTERNO",
        "ADM": "Pu",
        "INFRAESTRU": "HOSPITAL",
        "ADM_INFRAE": "NACIONAL",
        "RED_DE_SAL": ""
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.155020, -17.773330] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "H. JAPONES",
        "NIVEL": "HOSPITAL 3ER NIVEL",
        "DISTRITO": 2,
        "ZONA_ASOCIADA": "DM2 - Norte Interno",
        "UV": "",
        "MZ": "",
        "BARRIO": "",
        "DIRECCION": "AV. BUSCH Y TERCER ANILLO",
        "ADM": "",
        "INFRAESTRU": "HOSPITAL",
        "ADM_INFRAE": "DEPARTAMENTAL",
        "RED_DE_SAL": ""
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.187130, -17.778350] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSPITAL MATERNOLOGICO PERCY BOLAND",
        "NIVEL": "HOSPITAL 3ER NIVEL",
        "DISTRITO": 11,
        "ZONA_ASOCIADA": "DM11 - Centro",
        "UV": "36",
        "MZ": "26",
        "BARRIO": "",
        "DIRECCION": "C/RAFAEL PEÑA CASI AV. CAÑOTO"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.186670, -17.780710] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSPITAL DE NIÑOS \"MARIO ORTIZ\"",
        "NIVEL": "HOSPITAL 3ER NIVEL",
        "DISTRITO": 11,
        "ZONA_ASOCIADA": "DM11 - Centro",
        "UV": "CI",
        "MZ": "",
        "BARRIO": "",
        "DIRECCION": "CALLE BUENOS AIRES"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.189740, -17.854740] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSP. MUN. FRANCÉS",
        "NIVEL": "HOSPITAL 2DO NIVEL",
        "DISTRITO": 9,
        "ZONA_ASOCIADA": "DM9 - Palmasola/Sur",
        "UV": "129",
        "MZ": "39",
        "BARRIO": "URBANIZACIÓN CHIRIGUANO",
        "DIRECCION": "AV. SANTOS DUMONT 6TO ANILLO, B/PAITITI C/1 ENTRE C/MATICO Y C/1"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.209340, -17.832210] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSPITAL MUNICIPAL. BAJIO DEL ORIENTE",
        "NIVEL": "HOSPITAL 2DO NIVEL",
        "DISTRITO": 10,
        "ZONA_ASOCIADA": "DM10 - El bajío",
        "UV": "118",
        "MZ": "SN",
        "BARRIO": "SANTA CRUZ",
        "DIRECCION": "AV. SIMON BOLIVAR CALLE ESLOVAQUIA A 2 CUADRAS DEL 6TO ANILLO."
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.222510, -17.820884] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "CAJA NACIONAL DE SALUD \"EL BAJIO\"",
        "NIVEL": "POLICONSULTORIO",
        "DISTRITO": 10,
        "ZONA_ASOCIADA": "DM10 - El bajío",
        "UV": "127",
        "MZ": "",
        "BARRIO": "",
        "DIRECCION": "DISTRITO 10 - EL BAJIO, UV 127"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.109220, -17.839150] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSITAL MUNICIPAL PLAN 3000",
        "NIVEL": "HOSPITAL 2DO NIVEL",
        "DISTRITO": 8,
        "ZONA_ASOCIADA": "DM8 - Plan 3000",
        "UV": "162",
        "MZ": "ET132",
        "BARRIO": "",
        "DIRECCION": "B/ Piraicito Av. Prefectural Diagonal Mercado Los Pocitos A 2 Cuadras De La Av. Paurito"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.117940, -17.799490] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "HOSPITAL MUNICIPAL VILLA 1RO DE MAYO",
        "NIVEL": "HOSPITAL 2DO NIVEL",
        "DISTRITO": 7,
        "ZONA_ASOCIADA": "DM7 - Villa 1ro de Mayo",
        "UV": "ET 36",
        "MZ": "",
        "BARRIO": "LIBERTAD",
        "DIRECCION": "7MO ANILLO ENTRE CUMAVI Y AV. 3 PASOS AL FRENTE. B/ LIBERTAD AV. LA TRADICION A UNA CUADRA DE LA AV. LIBERTADORES"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.180130, -17.791520] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "CLINICA ANGEL FOIANINI",
        "NIVEL": "CLINICA PRIVADA",
        "DISTRITO": 11,
        "ZONA_ASOCIADA": "DM11 - Centro",
        "UV": "CIII",
        "MZ": "162",
        "BARRIO": "",
        "DIRECCION": "CALLE CHUQUISACA 737"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.195190, -17.788050] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "CLINICA INCOR",
        "NIVEL": "CLINICA PRIVADA",
        "DISTRITO": 1,
        "ZONA_ASOCIADA": "DM1 - Pirai",
        "UV": "61",
        "MZ": "P2",
        "BARRIO": "",
        "DIRECCION": "SOBRE CALLE ROBORE"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-63.174900, -17.800400] },
      "properties": {
        "SISTEMA": 3,
        "SUB_SISTEM": "B",
        "NOMBRE": "CLINICA LAS AMERICAS CIRUGIA PLASTICAS",
        "NIVEL": "CLINICA PRIVADA",
        "DISTRITO": 4,
        "ZONA_ASOCIADA": "DM4 - El pari",
        "UV": "26",
        "MZ": "",
        "BARRIO": "B/ Aeronautico",
        "DIRECCION": ""
      }
    }
  ]
}
```
