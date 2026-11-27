--!strict
-- Valores de "sensación" del arma en primera persona (viewmodel). Todo lo que se ajusta a ojo está acá.
--
-- Unidades: posiciones en studs, ángulos en grados (como la propiedad Orientation de Studio).
-- Ejes de la cámara: X = derecha, Y = arriba, Z = atrás (o sea, hacia adelante es Z NEGATIVO).
--
-- Modo ajuste (solo en Studio): durante el Play, estos mismos valores aparecen como atributos de
-- ReplicatedStorage.AjustesArma (en la vista Cliente del Explorer). Si los cambiás en Propiedades, el arma
-- cambia al instante. Para guardarlos, tildá el atributo "_Imprimir": se escriben en el Output y los copiás acá.
-- Los atributos se llaman "seccion_clave" (por ejemplo "cadera_posicion").

local ViewmodelConfig = {}

ViewmodelConfig.valores = {
	-- Tamaño del arma en primera persona (solo la ve el jugador; la de tercera persona no cambia).
	-- Se aplica al volver a equipar el arma.
	arma = {
		escala = 1.3, -- 1 = tamaño real del modelo; 1.3 = 30% más grande
	},

	-- Dónde está el arma cuando no apuntás. Es la posición del Handle respecto de la cámara.
	cadera = {
		-- Calculado a partir de la captura de referencia: en pantalla 16:9 la punta del cañón queda en (58%, 59%) y
		-- la parte de atrás del receptor sale por la esquina de abajo a la derecha.
		posicion = Vector3.new(1.02, -0.7, -1.36), -- derecha, abajo, adelante
		rotacion = Vector3.new(4.8, 8.4, 0), -- X positivo = cañón hacia arriba; Y positivo = gira hacia el centro
	},

	-- Apuntar (clic derecho o gatillo izquierdo del joystick): el arma va al centro y la mira (Aim_Att del arma)
	-- queda alineada con el centro de la pantalla, con un zoom suave.
	apuntar = {
		tiempo = 0.18, -- segundos que tarda en llevar el arma a la mira (y en volver)
		distancia = 1.6, -- qué tan lejos del ojo queda la mira (studs); menos = el arma se ve más grande
		posicion = Vector3.new(0, 0, 0), -- corrimiento fino de la mira si no queda justo en el centro
		campoVision = 55, -- campo de visión al apuntar (el normal de Roblox es 70; menos = más zoom)
		sensibilidad = 0.75, -- sensibilidad del mouse al apuntar (1 = igual que sin apuntar)
		balanceo = 0.3, -- cuánto balanceo queda al apuntar (1 = todo, 0 = nada)
		paso = 0.25, -- cuánto movimiento de paso queda al apuntar
		retroceso = 0.6, -- cuánta patada del arma queda al apuntar
		manoIzquierda = Vector3.new(0, -0.175, -0.25), -- dónde va la mano izquierda al apuntar (desde LeftGrip_Att)
	},

	-- Correr: al moverse rápido por el piso el arma baja y se cruza delante del cuerpo (cañón a la izquierda).
	-- Disparar, apuntar, recargar o inspeccionar la vuelven a subir enseguida.
	correr = {
		velocidadMinima = 12, -- studs/s: desde esta velocidad cuenta como correr (caminar normal en Roblox = 16)
		-- Calculado del video de referencia: en 16:9 la punta del cañón queda en (35%, 73%) y el receptor en (66%, 80%).
		posicion = Vector3.new(-0.38, -0.57, -1.14), -- studs que se corre el arma respecto de la cadera
		rotacion = Vector3.new(-5, 50, 0), -- grados (cabeceo, giro, ladeo); Y+ = el cañón apunta a la izquierda
		entrada = 6, -- qué tan rápido baja al empezar a correr (más = más rápido)
		salida = 16, -- qué tan rápido sube al frenar, disparar o apuntar
		pausaTrasDisparo = 0.35, -- segundos después de un tiro en los que no vuelve a bajar
	},

	-- Los resortes de abajo usan dos valores:
	--   frecuencia: qué tan rápido vuelve el arma a su lugar (más = más rápido y más duro).
	--   amortiguacion: 1 = vuelve sin rebotar; más bajo = rebota más antes de quedarse quieta.

	-- Balanceo: al girar la cámara el arma se atrasa un poco y vuelve sola con un resorte.
	balanceo = {
		intensidad = 0.025, -- grados de atraso por cada grado/segundo que gira la cámara
		maximo = 6, -- tope del atraso (grados)
		inclinacion = 0.6, -- cuánto se ladea al girar a los costados (0 = nada, negativo = al revés)
		desplazamiento = 0.015, -- cuánto se corre de lugar por cada grado de atraso (studs)
		frecuencia = 7,
		amortiguacion = 0.55,
	},

	-- Paso: el arma se mueve con cada pisada; cuanto más rápido vas, más se mueve.
	paso = {
		largoCiclo = 7, -- studs que caminás en un ciclo completo (un paso con cada pie)
		velocidadReferencia = 16, -- a esta velocidad (caminar normal) el movimiento es el de "amplitud" y "rotacion"
		maximo = 1.8, -- tope al correr: hasta cuántas veces la amplitud de caminar
		amplitud = Vector3.new(0.045, 0.035, 0), -- studs: de costado, arriba/abajo, adelante/atrás
		rotacion = Vector3.new(0.8, 1.2, 1.5), -- grados: cabeceo, giro, ladeo
		suavizado = 8, -- qué tan rápido arranca y se frena el movimiento al empezar o dejar de caminar
	},

	-- Salto y caída: un rebote del arma al despegar del piso y al aterrizar.
	salto = {
		impulsoSalto = 2.5, -- fuerza del rebote al saltar (más = baja más)
		impulsoAterrizaje = 5, -- fuerza del rebote al caer
		caidaReferencia = 50, -- velocidad de caída (studs/s) que da el rebote completo; caídas más lentas rebotan menos
		inclinacion = 15, -- grados que cabecea el arma por cada stud de rebote
		frecuencia = 4,
		amortiguacion = 0.45,
	},

	-- Retroceso del arma en cada disparo: patea hacia atrás y hacia arriba y vuelve con un resorte.
	-- Los valores son aproximadamente cuánto se mueve con UN disparo; en ráfaga se suman un poco.
	retroceso = {
		atras = 0.12, -- studs hacia atrás
		arriba = 0.03, -- studs hacia arriba
		cabeceo = 3, -- grados que sube el cañón
		lateral = 1, -- grados de giro hacia un costado (al azar, izquierda o derecha)
		ladeo = 2, -- grados de ladeo (al azar)
		frecuencia = 4,
		amortiguacion = 0.6,
	},

	-- Retroceso de la cámara: sube un poco en cada disparo y vuelve sola a donde estabas mirando.
	retrocesoCamara = {
		arriba = 0.6, -- grados que sube por disparo
		lateral = 0.25, -- grados hacia un costado (al azar)
		frecuencia = 4,
		amortiguacion = 0.9,
	},

	-- Brazos del viewmodel (copias de los brazos R15 de tu avatar, con su color y su camisa).
	-- "mostrar" y "escala" se aplican al volver a equipar el arma.
	brazos = {
		mostrar = true,
		escala = 0.7, -- grosor/tamaño de los brazos (1 = igual que el avatar)
		-- Cada brazo es la mano + el antebrazo RECTO, sin codo: sale de la mano en una dirección fija respecto del
		-- arma (ejes del arma: X = derecha, Y = arriba, Z = atrás) y es lo bastante largo para salir de la pantalla.
		-- Como la dirección es respecto del arma, el brazo la acompaña en todas las poses.
		largoAntebrazo = 3, -- studs (más largo que la pantalla, así nunca se ve dónde termina)
		antebrazoIzquierdo = Vector3.new(0, -1, 0.2), -- hacia abajo y apenas hacia atrás (sube desde abajo)
		antebrazoDerecho = Vector3.new(0.4, 0.19, 0.9), -- al correr, entra horizontal desde el borde derecho
		-- Dónde va la punta de cada mano, desde su attachment del arma (ejes del arma).
		-- La izquierda se eligió midiendo que la manga quede pegada al guardamanos sin meterse adentro.
		manoIzquierda = Vector3.new(0, -0.175, -0.25), -- desde LeftGrip_Att: debajo del guardamanos
		manoDerecha = Vector3.new(0, -0.1, 0.15), -- desde RightGrip_Att: rodeando la empuñadura
		-- El brazo derecho solo se muestra cuando hace falta (corriendo, o tirando del cerrojo en la recarga).
		-- Disparando o apuntando no se ve, como en los shooters de referencia.
		derechoSoloCuandoHaceFalta = true,
	},

	-- Recarga (tecla R, o X en joystick). Dura lo que diga "reloadTime" en WeaponConfig (lo cuenta el servidor).
	-- Los "momentos" van de 0 (empieza la recarga) a 1 (termina). Los movimientos de piezas van en los ejes
	-- del arma: X = derecha, Y = arriba, Z = atrás.
	recarga = {
		inclinacion = Vector3.new(10, 25, 35), -- grados (cabeceo, giro, ladeo); Z+ = muestra el lado derecho y la manija
		desplazamiento = Vector3.new(-0.5, 0.45, -0.1), -- studs que se corre (hacia el centro y arriba, para que se vea)
		entrada = 0.15, -- parte del tiempo que tarda en inclinarse al empezar
		salida = 0.15, -- parte del tiempo que tarda en volver al final
		cargadorSale = 0.18, -- momento en que empieza a salir el cargador
		cargadorFuera = 0.32, -- momento en que ya está afuera
		cargadorEntra = 0.5, -- momento en que empieza a volver
		cargadorDentro = 0.64, -- momento en que ya entró (ahí hay un golpecito)
		cargadorRecorrido = Vector3.new(0, -0.6, -0.1), -- studs hasta donde sale
		cargadorGiro = Vector3.new(25, 0, 0), -- grados que gira al salir (X positivo = la punta va hacia adelante)
		golpe = 3, -- grados que sube el arma al meter el cargador
		cerrojoTira = 0.72, -- momento en que empieza a tirar del cerrojo
		cerrojoAtras = 0.78, -- momento en que el cerrojo llega atrás
		cerrojoSuelta = 0.84, -- momento en que lo suelta (vuelve de golpe)
		cerrojoRecorrido = Vector3.new(0, 0, 0.3), -- studs que va hacia atrás
		manoCargador = Vector3.new(0, -0.3, 0.1), -- dónde agarra la mano izquierda el cargador (desde su bisagra)
		manoCerrojo = Vector3.new(0.3, -0.05, 0.05), -- dónde agarra la mano DERECHA la manija del cerrojo (lado derecho)
	},

	-- Inspeccionar (tecla V, o flecha arriba en joystick): el arma se acerca y gira para mostrar un costado y
	-- después el otro. Disparar, apuntar o recargar la cortan. Los "momentos" van de 0 a 1, como en la recarga.
	inspeccion = {
		duracion = 3.5, -- segundos que dura
		desplazamiento = Vector3.new(-0.55, 0.4, 0.1), -- studs que se corre (hacia el centro y arriba)
		primerGiro = Vector3.new(5, 55, -10), -- grados de la primera pose (muestra el lado izquierdo)
		segundoGiro = Vector3.new(-10, 25, 70), -- grados de la segunda pose (muestra el lado derecho y arriba)
		entrada = 0.15, -- parte del tiempo que tarda en llegar a la primera pose
		cambio = 0.45, -- momento en que empieza a girar a la segunda pose
		cambioDuracion = 0.15, -- parte del tiempo que tarda en ese giro
		salida = 0.15, -- parte del tiempo que tarda en volver al final
	},

	-- Cuando hay una pared delante, el arma se retira y se baja para no atravesarla.
	antiPared = {
		margen = 0.4, -- studs de más delante del cañón en los que ya empieza a retirarse
		profundidad = 1.5, -- si el cañón se metería esto (o más) en la pared, el arma se retira del todo
		retroceso = 0.8, -- cuánto se va hacia atrás con la pared pegada (studs)
		bajada = 0.2, -- cuánto baja (studs)
		rotacion = Vector3.new(-20, -45, 0), -- giro con la pared pegada (X- = cañón abajo, Y- = cañón a la derecha)
		velocidad = 12, -- qué tan rápido se acomoda (más = más brusco)
	},

	-- Efectos propios de la skin (partículas y luces de la Glaciar, por ejemplo) en el viewmodel.
	skin = {
		particulas = true,
	},
}

return ViewmodelConfig
