-- =====================================================
-- POLITIQUE DE SUPPRESSION DE COMPTE UTILISATEUR
-- =====================================================

-- Cette politique permet aux utilisateurs de supprimer leur propre profil
-- ATTENTION : Cette suppression ne supprime que le profil, pas le compte d'authentification Supabase
-- Pour une suppression complète, il faudrait aussi supprimer l'utilisateur de auth.users

-- Ajouter la politique de suppression pour les profils utilisateurs
CREATE POLICY "Users can delete own profile" ON public.user_profiles FOR DELETE USING (auth.uid() = id);

-- =====================================================
-- NOTES IMPORTANTES
-- =====================================================

-- 1. Cette politique permet seulement de supprimer le profil dans user_profiles
-- 2. Le compte d'authentification Supabase (auth.users) n'est PAS supprimé
-- 3. Les données liées (commandes, panier, favoris) peuvent être conservées selon la politique de rétention
-- 4. Pour une suppression complète, il faudrait :
--    - Supprimer l'utilisateur de auth.users (nécessite des privilèges spéciaux)
--    - Décider du sort des données liées (suppression en cascade ou anonymisation)

-- =====================================================
-- EXEMPLE D'UTILISATION
-- =====================================================

-- Pour supprimer son profil (depuis l'application) :
-- DELETE FROM public.user_profiles WHERE id = auth.uid();

-- =====================================================
-- POLITIQUE DE SUPPRESSION COMPLÈTE (OPTIONNELLE)
-- =====================================================

-- Si vous voulez permettre la suppression complète du compte,
-- vous pouvez créer une fonction avec des privilèges élevés :

/*
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Supprimer les données liées
    DELETE FROM public.cart_items WHERE user_id = $1;
    DELETE FROM public.favorites WHERE user_id = $1;
    DELETE FROM public.notifications WHERE user_id = $1;
    DELETE FROM public.payments WHERE user_id = $1;
    DELETE FROM public.orders WHERE user_id = $1;
    DELETE FROM public.user_profiles WHERE id = $1;
    
    -- Note: La suppression de auth.users nécessite des privilèges spéciaux
    -- et doit être gérée au niveau de l'API Supabase
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/ 