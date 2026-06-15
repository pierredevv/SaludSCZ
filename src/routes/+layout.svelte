<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { auth, isAuthenticated, userRole } from '$lib/stores/auth';

	let { children } = $props();

	let mobileMenuOpen = $state(false);

	onMount(() => {
		auth.init();
	});

	const navLinks = [
		{ href: '/', label: 'Inicio', public: true },
		{ href: '/dashboard', label: 'Dashboard', public: true },
		{ href: '/mapa', label: 'Mapa', public: true },
		{ href: '/casos', label: 'Casos', public: false },
		{ href: '/alertas', label: 'Alertas', public: true }
	];

	function getVisibleLinks(role: string | null) {
		return navLinks.filter((link) => link.public || (role && role !== 'ciudadano'));
	}

	async function handleLogout() {
		await auth.logout();
		mobileMenuOpen = false;
	}
</script>

<svelte:head>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

<nav class="navbar">
	<div class="nav-container">
		<a href="/" class="nav-brand">
			<span class="brand-icon">&#127973;</span>
			<span class="brand-text">Salud<span class="brand-highlight">SCZ</span></span>
		</a>

		<button class="mobile-toggle" onclick={() => (mobileMenuOpen = !mobileMenuOpen)}>
			{#if mobileMenuOpen}&#10005;{:else}&#9776;{/if}
		</button>

		<div class="nav-links" class:open={mobileMenuOpen}>
			{#each getVisibleLinks($userRole) as link}
				<a href={link.href} class="nav-link" onclick={() => (mobileMenuOpen = false)}>
					{link.label}
				</a>
			{/each}
		</div>

		<div class="nav-auth">
			{#if $isAuthenticated}
				<span class="user-info">
					<span class="user-icon">&#128100;</span>
					<span class="user-role">{$userRole}</span>
				</span>
				<button class="btn btn-outline btn-sm" onclick={handleLogout}>Salir</button>
			{:else}
				<a href="/login" class="btn btn-primary btn-sm">Iniciar Sesion</a>
			{/if}
		</div>
	</div>
</nav>

<main class="main-content">
	{@render children()}
</main>

<footer class="footer">
	<div class="footer-container">
		<p>SaludSCZ - Sistema de Vigilancia Epidemiologica Tropical</p>
		<p class="footer-sub">Feria Facultativa 2026 - Bases de Datos I - Universidad Autonoma Gabriel Rene Moreno</p>
	</div>
</footer>

<style>
	.navbar {
		background: var(--color-surface);
		border-bottom: 1px solid var(--color-border);
		position: sticky;
		top: 0;
		z-index: 100;
	}

	.nav-container {
		max-width: 1280px;
		margin: 0 auto;
		padding: 0 1rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		height: 60px;
	}

	.nav-brand {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 1.25rem;
		font-weight: 700;
		color: var(--color-text);
	}

	.brand-icon {
		font-size: 1.5rem;
	}

	.brand-highlight {
		color: var(--color-primary);
	}

	.nav-links {
		display: flex;
		gap: 0.25rem;
	}

	.nav-link {
		padding: 0.5rem 1rem;
		border-radius: var(--radius);
		color: var(--color-text-muted);
		font-weight: 500;
		transition: all 0.2s;
	}

	.nav-link:hover {
		background: var(--color-surface-2);
		color: var(--color-text);
	}

	.nav-auth {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.user-info {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		font-size: 0.85rem;
		color: var(--color-text-muted);
	}

	.user-icon {
		font-size: 1.2rem;
	}

	.user-role {
		text-transform: capitalize;
		font-weight: 500;
	}

	.btn-sm {
		padding: 0.35rem 0.7rem;
		font-size: 0.8rem;
	}

	.mobile-toggle {
		display: none;
		background: none;
		border: none;
		color: var(--color-text);
		font-size: 1.5rem;
		cursor: pointer;
		padding: 0.25rem;
	}

	.main-content {
		min-height: calc(100vh - 60px - 80px);
		padding: 2rem 1rem;
		max-width: 1280px;
		margin: 0 auto;
	}

	.footer {
		background: var(--color-surface);
		border-top: 1px solid var(--color-border);
		padding: 1.5rem 1rem;
		text-align: center;
	}

	.footer-container {
		max-width: 1280px;
		margin: 0 auto;
	}

	.footer p {
		color: var(--color-text-muted);
		font-size: 0.85rem;
	}

	.footer-sub {
		margin-top: 0.25rem;
		font-size: 0.75rem !important;
		opacity: 0.7;
	}

	@media (max-width: 768px) {
		.mobile-toggle {
			display: block;
		}

		.nav-links {
			display: none;
			position: absolute;
			top: 60px;
			left: 0;
			right: 0;
			background: var(--color-surface);
			border-bottom: 1px solid var(--color-border);
			flex-direction: column;
			padding: 0.5rem;
		}

		.nav-links.open {
			display: flex;
		}

		.nav-link {
			padding: 0.75rem 1rem;
		}

		.nav-auth {
			display: none;
		}
	}
</style>
