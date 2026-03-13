# **Documento de Especificaciones para el Modelo de Evaluación de Valor de Propiedad**

Este documento detalla los requerimientos técnicos para el desarrollo de un script en lenguaje R destinado a simular el impacto de intervenciones urbanas en el valor del suelo.

## **1\. Requerimientos Funcionales**

### **RF-01: Gestión de Insumos Espaciales y Tabulares**

El código debe ser capaz de procesar los siguientes archivos de entrada:

* **Ráster de Cobertura (clasificacion.tif):** Archivo tipo ráster que representa el estado actual del uso de suelo.  
* **CSV de Elasticidades (elasticidades.csv):** Tabla con parámetros estadísticos (tipo, elasticidad, desv, dist, rampa).  
* **Polígonos de Intervención:** Archivos en formato vectorial (.geojson, .shp, o .kml).  
* **CSV de Mapeo de Intervenciones:** Tabla que vincula los archivos espaciales con el tipo de intervención definido en el catálogo de elasticidades.

### **RF-02: Cálculo de Distancia Euclidiana**

Para cada píxel del ráster de entrada, el código debe calcular la distancia mínima hacia la geometría de intervención más cercana. El cálculo debe ser compatible con proyecciones métricas para asegurar que la unidad de medida sea metros.

### **RF-03: Aplicación del Modelo de Decaimiento (Rampa)**

El impacto en el valor del suelo debe seguir una función lineal de decaimiento basada en la distancia:

* **Punto de Origen (0m):** Se aplica el 100% del valor de la elasticidad.  
* **Pendiente de Reducción:** Según el requerimiento, el efecto decrece un **16% por cada 100 metros** de distancia.  
* **Límite de Efecto:** El impacto debe truncarse a cero (0) una vez que el factor de reducción iguale o supere el 100% (aproximadamente a los 625 metros con una rampa de 0.16).  
* **Fórmula Base:![][image1]**

### **RF-04: Análisis de Incertidumbre y Error**

El código no debe limitarse a un valor determinista. Debe utilizar las columnas desv (desviación estándar) y dist (tipo de distribución) para:

* Generar un intervalo de confianza o margen de error para el cambio esperado.  
* Si dist es "normal", usar qnorm para los cálculos de error.  
* Si dist es "t", usar qt con los grados de libertad correspondientes.

### **RF-05: Generación de Productos (Salidas)**

* **Ráster de Cambio Porcentual:** Un archivo .tif donde cada píxel represente el % de incremento/decremento esperado en el valor del suelo.  
* **Reporte Numérico:** Un resumen estadístico que indique el cambio medio esperado y el margen de error calculado para la zona de estudio.

## **2\. Requerimientos No Funcionales**

### **RNF-01: Eficiencia en Procesamiento Espacial**

Dado que el cálculo de distancias sobre rásteres de alta resolución puede ser intensivo, se requiere el uso de librerías optimizadas como terra o stars en lugar de librerías obsoletas como raster.

### **RNF-02: Precisión Geográfica**

El código debe verificar automáticamente que el SRC (Sistema de Referencia de Coordenadas) del ráster y de los polígonos coincida. En caso de discrepancia, debe realizar una reproyección automática al sistema del ráster.

### **RNF-03: Modularidad del Código**

El código debe estructurarse mediante funciones claras:

1. load\_data(): Para la ingesta y validación de archivos.  
2. calculate\_impact(): Para la lógica matemática del decaimiento.  
3. estimate\_uncertainty(): Para los cálculos estadísticos de distribución.

### **RNF-04: Manejo de Errores**

El sistema debe validar la existencia de las columnas requeridas en los archivos CSV antes de iniciar el proceso. Si falta una columna (ej. rampa), el script debe detenerse con un mensaje de error descriptivo.

### **RNF-05: Portabilidad y Reproducibilidad**

Se recomienda el uso de rutas relativas y la gestión de dependencias mediante un archivo de encabezado que instale/cargue las librerías necesarias (sf, terra, tidyverse).

## **3\. Lógica de Negocio (Resumen del Proceso)**

1. **Lectura:** Se cargan los parámetros y la geometría.  
2. **Rasterización/Distancia:** Se genera un mapa de distancias desde el polígono de intervención hacia toda el área de estudio.  
3. **Transformación:** Se aplica la elasticidad base ajustada por el factor de rampa según la distancia de cada celda.  
4. **Simulación:** Se calcula el margen de error utilizando los parámetros de distribución para el valor final.  
5. **Escritura:** Se exporta el ráster final con los cambios porcentuales.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAmwAAABQCAYAAACksinaAAAScElEQVR4Xu2dC7RtVVnHL2JF79cglHvunuvcewult1QaWallck3DTBEZldHQTC1JEM3S8m0p9gA0Bj6wyBQpyiQzISWwBwgU2AB8RfgChK6oqCDI7fuv9c19v/PttfbZ95579zn33N9vjDn2mv9vzrkeez2+Ndd8bNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADLUEq5wsJ/WvgvC1dZuHI0Gl1qv5dYODmnBwAAAIBVwByzCy3ssLBYtaZpHmTx7dIXFhY2xvTi8MMP/2rZsj4Llu/UrM0b39/7Zh0AAABgTeLOS6/zpVq2IdvuYGXdsifLAwAAANgvkAM1Go3+JevikEMO+fo96WD5uv4u6wAAAAAwgDlPx3gN20OzTTRNc1B22CzPT5n2mqhFLM/xZv8rS/fgqln8kR7ksD1HyzGP2LRp0w+ZfmbWhekvtfDsED/SyjlDDmVMF7HtONrSnaftCdp9tG1bt279ppi2YrZftXL/2BYPyDYAAACAVcEclGuyQxYx5+Vx0a6auIWFha2mvc/CnTGt299kTlGjZft5nqX5HS3b74kWLlBZvnxizGfxOyz9n/uy0uxYXFw8rNo3btz47a6rM8RtFh7qYWLbTdvmaVsntLhzaQ7hz9k6XmTb+NMD+W6wdRZfvkdpLP1TczoAAACAueKOzYTzUjHbvwX7Abb8ZtfvtvDlkLQlluUOzx+GeG/7NdNut3BXiL86lfMC/93h+r2DTTV245o8W364tM2bN49imvR7Wt4O286ro2blPNrjB4ZkAAAAAPNHTolqnbJeCU7SmMXFxe+XdsQRR3xV1EVNn52majNH6ISkqaZuSfme//aoVV0OWY2rrIG8g59rhdLYPv9WiOtz65IaPYv/by4bAAAAYFVw5+WgrAuzneuOzCFJv3nImVlYWPhed5raUPVNmzZ9j8fvFZL3OoS+Tc+LmsWf0JNOtXx3J23HYYcd9o1Ri5iT98yectrPn0mTc/hPUQMAAACYO6oBy45KxRykxp2ptg1axPWTtFxr2TRWm2mfrWly2bb81zFuztBvuq6ybqx61VSuHC/bjB9w7dq8rYqb/UlaHnnP05wm4+u71ZefHLSJsq3MH4saAAAAwNwxp+QvS0/HAdOeLodFjfSzTQ5SdW5s+X5VN+2T0enR58UYd6do/JnTlm8O+nVV37Jly6aaL9Zwebp/rfGq6VeOVXXc4jorth9baq2b7Bb/4Wg37VNpWy+q8VzTBwAAAKuEPZw/vmGdDuOwefPm78qaOThvLd10VHKCvmjh3xXMOblMmtkvbQY+k5rtuz3ffUvodGDL2yzPxeoA0HTDemiGhG8L9tM932IJnzFVgyZdn11t+WmNN/43p+pQ+/1gyL+kc0HV3MH7TNDkON5mi/e23wdYuM7KfHvMs3Xr1oNLcB7tGH2zl3+41m+/j1fclhv7vaOmW8/Yf/WdfW0ShR2De7IGsK7wi/2zuvBDuCWng5Vhx/RL6Rj3Bk/7Dxa+UuPzxB4CZ1n4paxPo3RjQk1tR2NpbvV91ENqt7H8n4nHan/Bju8rsiaKt9+ycM2hhx76ddk+I3IaJnpSzgNzeH7c9u1dWYe1j657CzdauNseI3+Q7dOwPGdbuH/WK/5cusnCHbGThdvksB8XtUrp7g+D5QKsC3TT3JcfgrbtX8zaWkTHWG/OPfrPxuPvN8P3xTR7Civ31IH/WsMh6I19V2++O0pPb7mMlXuOnWfPzfquUqY0Jl+n3Ktvf007N/RwPND/h5nnnbS0b/E8bcj2vc1K5vmE1UXnnoVPhbg+W08993Tfs+v/Y/V8U01hTiNMP6P48Clbtmz5jr5zpE8Tlvdbh2wA64bVumnvKfaFbfcR0ge3M9pKNzjmz0T7nsL/6+1Z39tovUOfM3YFv9lPrdFbT5ij+24Lf5r1fC5Z/JSszYLl+dzu5Fspts7LLbw467D28fNlPM5c0JaldJ+Aex22UTc7RbwPXtV33yjdcCanRa1Sut60v5B1gHWDLoqSup7vK9TxlrK+1rBtPD9vZwljMdnyB8LyXtsfld2E8Z3mxZ7aJ5UzWkHPOMv/9KytZfy4LXk42v/3J/l4WvzIrM1CWT2Hbe7rhD1D33/Xp/VRpjhs0i18OGr6PBrjwvI+amh9pXtxmeikArAuMIfnR/xCeWW2mXai7CGuT3Wn17hXQZ8y6ua1W4JdZ48IbW8OtOU3lYE3arMdY+GXsx7ZuHHjgspofABNW35w6eb9q1PJPDKPxSQs/bEW3mbpH59t88S3MT9kx/F4Y8rpImZ72XLHyop6oKV7gx2P7wvaUY03tLbw8zpe1abxp6zMszak8acq3uD5NOWPumnHqXdb1CrKozIt/JpuzkP7ZPqZqn3MesTy/37TOSltz8Bsz5QwdEPE9IusnKOz3oM+Dz/Zwqu03xIs37O0HfFt32xvtvD8ndk61JDd9NMt/ccsvEtTFkW7lfUQs/+oh0V9HlSvQP1fFn9ATWd5N/ftr2lfzrrlLVmbhYLDtl9h59TLs1aRrfgwIlNoP79nUZqFx2Y9o/NbaXVPiLrmTfUy6vX2iGjP9G2DKF1Hk14bwD7P0A27eO8nv4jUsHTcI8u1r9S4P5CvCfGX+0NeDp7abX2NdE2CHNdly/+R4ip3ybZYWa9wre0hVzoH7cpq9zx/M86wUz+9CZ+SlmszY2kvNvv1M4a/zfmXobYxWhIa7+YfkZMjW9bLDMeq6ht2Hit9Hhg74rb86Zyn3jiL95BLtnbqmzoJdVxn6Xot1vUtQY5K6n03sa2lG1D0nz1aj8+STgkWvyOkqeV8KaYZwtJ9tITJwkuYVmhWfH132v/0GMXr+Vu6jjntdEBy4qT15BtfD7Z8h+a2jGmszCbm07KV9ZyU5u25bOHlL9HrPJZRm4UycP3vTTR8RfHpo2D+2LF/h4WTkzbTOVC6l4yJtNKaMMXXEGXAYbO8L/LzWi9b9dq6tAxc717Go7MuZJs2MDHAPotfJH0XYHuhuP3IZMsPKF2EN2S7XYSXWXjizpQ7bdUZUNf4aCuhAXvj3enjxW3ahyy+2aNtQ/lYkyS8pqJvnya0eaAHse/btqoNbYunW1KlP8uxEuHzcPsJzZY/mmqElOe8cYZOaztsuO3TVVevQ9fGb9we3yYnxf6Hb6latXv85B5N+d4b4u/vS9OE8aRK11t2Io3WHbVpFHfarNyLs20WfLsntqGEF4a+ton5QVK6mrpzo+a6yrrE0j+88UnFk11teD7Xo09sl9fq9Z5T01D5u5NvJZRuQvSXZB3mhx3/8+sLgi2/OtuHKAOf3qVZeX+W9Uxxh021+lHX+e/n9fur5kObqNxjYlrhaZ+ddeHlT621B9gXUZd+nfiXZ0MlX5xylkp667H4O+2C+/WouZ4fdvpu02q+3mzPD+2JNBGz/UaffShfnzYPbL2fz+uOcVu+NuolPcz69kfxeKyEnLOa1sKdeagH6XLqoiZqPjnIVSszPMjtXDhh5KO3V6Zs60+mNOOR483WSOtxLidGl6+1tbNSulrGU7I+C0P7UsIDLrwcLBkjzXu4aeT822RvwjhbFdPv7+V9IduE6f9n4b979IntGupRtxxlhv9ZaKy0ut7lQs6bsWNxvELWRS6LsGshH89pWPrz9TJjv6/NtiGGXgyk6X6Q9Uxxh03TgyW9fdGz8NKkS/tE1Kpu6zsj60I2269jsw6wT1MvEjvxH5VtonTtAZZ8SrL4X9jF8MKkTVzAIusWf33V/EIcP5BDG5xxA2u/8C6r8YzZb8nrcH0in2nb+tLOA9/XwXUXvyHVqXL6HK3ljlXF9vtos93et84cr5h+XrZ5/qkdUZQm9eBqh6Cw8JYq2Ln1lFh2rS207Xxq0M6KaZquDd6SNCJv43JY+iut7MdZOVdn2yz4vvQdl/Fn5tHO9nnj9n+lG3fvrjBy/fP7HDYR1jExKG7pelJOjF1Xej5tV4cqarNQZnTY9iR2LJ5k4VeyDvPFr7vrLLwg26bRd75IW5yhZ3txhy2/ONr5cJT0UWqfK630NGfwtL+XdeHl/0TWAfZpig+am/WK3mCaNC6X0jehPVt84xqFNji6eHPZfvG1I1J7Ob0P7eI9+TzNb9c0Gbf/vZY1CGdtN+UXczsPYEjbDt4atYjZPmLhzlmClX1pzj9EqL3qdTxtm7+2+BhG9vuGuo1laduzZY9V0zk540GPbfm4msZpPx/XiMqoy9ItvMOX31u10fRBTdvaWS003uvU0h8hbTEMdmnxT9R0Zv9FWz4pbVddf/tp1sp6d18atQErPqK70kRbH8WdtRDvrcWahm9X37ZGh60dVX+Dt7upaeqyx1+s81S1cY1/Snb9covfr3QDJU8MXlu68a0mzlnL87Ssm/aYrM1CWR2H7UGNdx6C1UHX/8g7i+k8y/Zp9J0vfVofxR02Cz/YY5M+0bau73qXnp27imxhjEKAdUH7AJ92ofXZsmbxC6X5JMjjdjim3RXTlu7BfVOIa92vT/F2+pbijofSW/ifmkbYRfpcW0/jdlWtt4255VzWNKWb+mXcPdyWP2jh+hqfJ41PpRMf1KJ0n4fVxioeIznQrWOhBu5B31H8WNnv73o8HyvdwMYj4lv8BgvPCHENztvemO33PDkKwdZug/2eVDsY6CZZ9ZBue+O9t1SW7PoU16TP2HLMfPkixUvXKWSJQ6PperRseT/keU5QzWHjzl9KI6emdcJjmiHKwFQ9pl81SlMHTcO3PR8D/ZfxPH+YtMXQQ7knj66FD1i+Fx588MHfsKG79s4ehRecsK5xrem0WrOSpuLx/KeGuD6n6pgt6ciQKd20T73r2JuUNOcmzI++/1vnYxloE5bRuWfn1VtDXPeW8bnnmq6Tt0XNdfXs7/2qU7yTWo37PWjcuS3Stw9idzvfAKxZSvfJTG1rdFPXdB76hDPRzief+PXBGTW1KZJm4cKou3am/+rifVa0e5ovuO3q0Mg9P+yuqHrpBkwcv5kVHyy09Dygm65tRs33sGyfB6WrOVEbqrodNUhTL0nV2H2kpq/tkGSP5Yiy81g9ZMqxamcB8HQTw1cE2wOTvl263USfGfXGeyl6yIPt1p6dV0TRawy1b/fIudL8f55uXINUP+kqePrHerydbDunKd7VP6fZHcoMjd19iAF9bv+4By2rF61eIBTXy4eca103ejmQpsm5qxPdjrnn4QLXtPxab0it/0l5WufcjvMTS/eZU+VqBPnx51Hl2zAw3Ipslvec0g3z8cZo0yen0l3f485AkdKNVq+pheo+aj/yf7zX8P2COdNMmShe55DZn5D1PnTONd3L1iV9/6Vpr6kvf0HTM0fneL2GdM4vOT+Lz8RSupfZz0dbpe/rTWXUDU2yy7XpAPstdUwdjZ2WbQAwO/5Qe1nWZ8Xy/mPW1gJDD1yA5bBz51rVtmddmO2u3KEBAKZgF80fcUMGWDleA7lb11LTNMev1Zcm26eblvtcO2/K9N7yGorkOv0XZWAMudLVWsp+Te44BHuOoeshj/MJAMtgF8wz/KalzzUTQ30AwK5h19J7sjYLJbQZXWvYveGgtfBw9c9rbW/zoe0x/cQSminovmbhqJTm3NDQvTYXmDohOuw6dkwvzMe+YrYb1+oLCgAA7CcUbx+33hhyklaDgW0Z94aORG3UM/WaORXHZg1WxsLCwkbVOGddlIHOCQAAALBnOEAdU7K4GvQ5WKa9bkBXJ52n+PKHcxqN5J81AAAAAFghfQ5W6Xqm9+k7irdl8+Vcw3afrAEAAADACulzsEo39E6frhq2dgDtPoeN8cAAAAAA9gJ9Dlbpxrjr0+WktXMA9zlsQ3NuAgAAAMAK6HOwTHvPgC4n7XW+rIGil6TRLB1ZAwAAAIAV0udgFZ8KrkfXsEXtrAC2fEFOY/EjswYAAAAAK2TIwZKuT5xZq8t9HQw0KHDWAAAAAGCFyMHSXK89uuaQvb7G3UFbModuSfP/qqySJkQHAAAAgN3Ax0vbbuGTZeek5Jr54OyYzuK3WrjZwjvljEVbRbo5c+eUrqPCG7MdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHaT/we+XTQV18jpDQAAAABJRU5ErkJggg==>