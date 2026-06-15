<script lang="ts">
	import { goto } from '$app/navigation';
	import { auth, isAuthenticated } from '$lib/stores/auth';

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let error = $state('');

	$effect(() => {
		if ($isAuthenticated) {
			goto('/casos');
		}
	});

	async function handleLogin(e: Event) {
		e.preventDefault();
		if (!email || !password) {
			error = 'Por favor ingrese email y contrasena.';
			return;
		}

		loading = true;
		error = '';

		try {
			await auth.login(email, password);
			goto('/casos');
		} catch (err: any) {
			error = err?.message ?? 'Error al iniciar sesion. Verifique sus credenciales.';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Iniciar Sesion - SaludSCZ</title>
</svelte:head>

<div class="login-wrapper">
	<div class="card login-card">
		<div class="login-header">
			<span class="login-icon">&#127973;</span>
			<h1>Salud<span class="highlight">SCZ</span></h1>
			<p>Inicie sesion para acceder al sistema</p>
		</div>

		{#if error}
			<div class="error">{error}</div>
		{/if}

		<form onsubmit={handleLogin}>
			<div class="form-group">
				<label for="email">Correo Electronico</label>
				<input
					id="email"
					type="email"
					bind:value={email}
					placeholder="usuario@saludscz.bo"
					required
				/>
			</div>

			<div class="form-group">
				<label for="password">Contrasena</label>
				<input
					id="password"
					type="password"
					bind:value={password}
					placeholder="Ingrese su contrasena"
					required
				/>
			</div>

			<button type="submit" class="btn btn-primary login-btn" disabled={loading}>
				{#if loading}Ingresando...{:else}Iniciar Sesion{/if}
			</button>
		</form>

		<div class="login-footer">
			<p>Sistema de Vigilancia Epidemiologica Tropical</p>
			<p class="hint">Credenciales de prueba en el README del proyecto</p>
		</div>
	</div>
</div>

<style>
	.login-wrapper {
		display: flex;
		align-items: center;
		justify-content: center;
		min-height: 60vh;
	}

	.login-card {
		width: 100%;
		max-width: 420px;
		padding: 2rem;
	}

	.login-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.login-icon {
		font-size: 3rem;
		display: block;
		margin-bottom: 0.5rem;
	}

	.login-header h1 {
		font-size: 1.75rem;
		font-weight: 700;
		margin-bottom: 0.25rem;
	}

	.highlight {
		color: var(--color-primary);
	}

	.login-header p {
		color: var(--color-text-muted);
		font-size: 0.9rem;
	}

	.login-btn {
		width: 100%;
		justify-content: center;
		margin-top: 0.5rem;
		padding: 0.75rem;
	}

	.login-footer {
		text-align: center;
		margin-top: 1.5rem;
		padding-top: 1rem;
		border-top: 1px solid var(--color-border);
	}

	.login-footer p {
		color: var(--color-text-muted);
		font-size: 0.8rem;
	}

	.hint {
		margin-top: 0.25rem;
		font-size: 0.75rem !important;
		opacity: 0.7;
	}
</style>
