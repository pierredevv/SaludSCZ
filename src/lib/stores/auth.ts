import { writable, derived } from 'svelte/store';
import { supabase } from '$lib/supabase';
import type { User, Session } from '@supabase/supabase-js';

interface AuthState {
	user: User | null;
	session: Session | null;
	rol: string | null;
	usuarioId: number | null;
	loading: boolean;
}

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>({
		user: null,
		session: null,
		rol: null,
		usuarioId: null,
		loading: true
	});

	let initialized = false;

	async function init() {
		if (initialized) return;
		initialized = true;

		const { data: { session } } = await supabase.auth.getSession();

		if (session?.user) {
			const { data: usuario } = await supabase
				.from('usuario')
				.select('id_usuario, rol')
				.eq('email', session.user.email)
				.single();

			set({
				user: session.user,
				session,
				rol: usuario?.rol ?? null,
				usuarioId: usuario?.id_usuario ?? null,
				loading: false
			});
		} else {
			set({
				user: null,
				session: null,
				rol: null,
				usuarioId: null,
				loading: false
			});
		}

		supabase.auth.onAuthStateChange(async (_event, newSession) => {
			if (newSession?.user) {
				const { data: usuario } = await supabase
					.from('usuario')
					.select('id_usuario, rol')
					.eq('email', newSession.user.email)
					.single();

				set({
					user: newSession.user,
					session: newSession,
					rol: usuario?.rol ?? null,
					usuarioId: usuario?.id_usuario ?? null,
					loading: false
				});
			} else {
				set({
					user: null,
					session: null,
					rol: null,
					usuarioId: null,
					loading: false
				});
			}
		});
	}

	async function login(email: string, password: string) {
		const { data, error } = await supabase.auth.signInWithPassword({
			email,
			password
		});

		if (error) throw error;

		if (data.user) {
			const { data: usuario } = await supabase
				.from('usuario')
				.select('id_usuario, rol')
				.eq('email', data.user.email)
				.single();

			set({
				user: data.user,
				session: data.session,
				rol: usuario?.rol ?? null,
				usuarioId: usuario?.id_usuario ?? null,
				loading: false
			});
		}

		return data;
	}

	async function logout() {
		await supabase.auth.signOut();
		set({
			user: null,
			session: null,
			rol: null,
			usuarioId: null,
			loading: false
		});
	}

	return {
		subscribe,
		init,
		login,
		logout
	};
}

export const auth = createAuthStore();

export const isAuthenticated = derived(auth, ($auth) => !!$auth.user);
export const userRole = derived(auth, ($auth) => $auth.rol);
export const canRegisterCase = derived(auth, ($auth) =>
	$auth.rol === 'admin' || $auth.rol === 'medico' || $auth.rol === 'enfermero'
);
