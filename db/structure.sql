--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: text_element; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE text_element AS ENUM (
    'input',
    'textarea'
);


--
-- Name: check_collection_cover_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_collection_cover_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF
              (SELECT
                (SELECT COUNT(1)
                 FROM collection_media_entry_arcs
                 WHERE collection_media_entry_arcs.cover IS true
                 AND collection_media_entry_arcs.collection_id = NEW.collection_id)
              > 1)
              THEN RAISE EXCEPTION 'There exists already a cover for collection %.', NEW.collection_id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: check_collection_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_collection_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.collection_id = NEW.collection_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for collection %.', NEW.collection_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_filter_set_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_filter_set_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.filter_set_id = NEW.filter_set_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for filter_set %.', NEW.filter_set_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_madek_core_meta_key_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_madek_core_meta_key_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              IF (OLD.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key % may not be deleted', OLD.id;
              END IF;
            ELSIF  (TG_OP = 'UPDATE') THEN
              IF (OLD.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key % may not be modified', OLD.id;
              END IF;
            ELSIF  (TG_OP = 'INSERT') THEN
              IF (NEW.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key namespace may not be extended by %', NEW.id;
              END IF;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: check_media_entry_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_media_entry_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.media_entry_id = NEW.media_entry_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for media_entry %.', NEW.media_entry_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_meta_data_meta_key_type_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_meta_data_meta_key_type_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN

            IF EXISTS (SELECT 1 FROM meta_keys 
              JOIN meta_data ON meta_data.meta_key_id = meta_keys.id
              WHERE meta_data.id = NEW.id
              AND meta_keys.meta_datum_object_type <> meta_data.type) THEN
                RAISE EXCEPTION 'The types of related meta_data and meta_keys must be identical';
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: check_meta_key_meta_data_type_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_meta_key_meta_data_type_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN

            IF EXISTS (SELECT 1 FROM meta_keys 
              JOIN meta_data ON meta_data.meta_key_id = meta_keys.id
              WHERE meta_keys.id = NEW.id
              AND meta_keys.meta_datum_object_type <> meta_data.type) THEN
                RAISE EXCEPTION 'The types of related meta_data and meta_keys must be identical';
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: check_users_apiclients_login_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_users_apiclients_login_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (EXISTS (SELECT 1 FROM users, api_clients
              WHERE api_clients.login = users.login
              AND api_clients.login = NEW.login)) THEN
          RAISE EXCEPTION 'The login % over users and api_clients must be unique.', NEW.login;
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: collection_may_not_be_its_own_parent(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION collection_may_not_be_its_own_parent() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF
              (SELECT
                (SELECT COUNT(1)
                 FROM collection_collection_arcs
                 WHERE NEW.parent_id = NEW.child_id
                )
              > 0)
              THEN RAISE EXCEPTION 'Collection may not be its own parent %.', NEW.collection_id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: delete_empty_meta_data_groups_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_groups_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_groups ON meta_data.id = meta_data_groups.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_groups_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_groups_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_groups ON meta_data.id = meta_data_groups.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_keywords_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_keywords_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_keywords ON meta_data.id = meta_data_keywords.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_keywords_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_keywords_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_keywords ON meta_data.id = meta_data_keywords.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_licenses_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_licenses_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_licenses ON meta_data.id = meta_data_licenses.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_licenses_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_licenses_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_licenses ON meta_data.id = meta_data_licenses.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_people_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_people_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_people ON meta_data.id = meta_data_people.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_people_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_empty_meta_data_people_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_people ON meta_data.id = meta_data_people.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_meta_datum_text_string_null(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_meta_datum_text_string_null() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF ((NEW.type = 'MetaDatum::Text' OR NEW.type = 'MetaDatum::TextDate')
                AND NEW.string IS NULL) THEN
              DELETE FROM meta_data WHERE meta_data.id = NEW.id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: groups_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION groups_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.name::text, '') || ' ' || COALESCE(NEW.institutional_group_name::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: licenses_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION licenses_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.label::text, '') || ' ' || COALESCE(NEW.usage::text, '') || ' ' || COALESCE(NEW.url::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: people_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION people_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.first_name::text, '') || ' ' || COALESCE(NEW.last_name::text, '') || ' ' || COALESCE(NEW.pseudonym::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
             NEW.updated_at = now();
             RETURN NEW;
          END;
          $$;


--
-- Name: users_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION users_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.login::text, '') || ' ' || COALESCE(NEW.email::text, '') ;
   RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE admins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE api_clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    login character varying NOT NULL,
    description text,
    password_digest character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT name_format CHECK (((login)::text ~ '^[a-z][a-z0-9\-\_]+$'::text))
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE app_settings (
    id integer DEFAULT 0 NOT NULL,
    featured_set_id uuid,
    splashscreen_slideshow_set_id uuid,
    site_title character varying DEFAULT 'Media Archive'::character varying NOT NULL,
    support_url character varying,
    welcome_title character varying DEFAULT 'Powerful Global Information System'::character varying NOT NULL,
    welcome_text character varying DEFAULT '**“Academic information should be freely available to anyone”** — Tim Berners-Lee'::character varying NOT NULL,
    teaser_set_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    brand_logo_url character varying DEFAULT '/assets/inserts/image-logo-zhdk.png'::character varying NOT NULL,
    brand_text character varying DEFAULT 'ACME, Inc.'::character varying NOT NULL,
    sitemap jsonb DEFAULT '[{"Medienarchiv ZHdK": "http://medienarchiv.zhdk.ch"}, {"Madek Project on Github": "https://github.com/Madek"}]'::jsonb NOT NULL,
    context_for_show_summary character varying,
    contexts_for_show_extra text[] DEFAULT '{}'::text[],
    contexts_for_list_details text[] DEFAULT '{}'::text[],
    contexts_for_validation text[] DEFAULT '{}'::text[],
    contexts_for_dynamic_filters text[] DEFAULT '{}'::text[],
    catalog_title character varying DEFAULT 'Catalog'::character varying NOT NULL,
    catalog_subtitle character varying DEFAULT 'Browse the catalog'::character varying NOT NULL,
    catalog_context_keys character varying[] DEFAULT '{madek_core:keywords}'::character varying[] NOT NULL,
    featured_set_title character varying DEFAULT 'Featured Content'::character varying,
    featured_set_subtitle character varying DEFAULT 'Highlights from this Archive'::character varying,
    CONSTRAINT oneandonly CHECK ((id = 0))
);


--
-- Name: collection_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_api_client_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collection_collection_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_collection_arcs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    child_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    highlight boolean DEFAULT false
);


--
-- Name: collection_filter_set_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_filter_set_arcs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    filter_set_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    highlight boolean DEFAULT false
);


--
-- Name: collection_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_group_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collection_media_entry_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_media_entry_arcs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    media_entry_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    highlight boolean DEFAULT false,
    cover boolean
);


--
-- Name: collection_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collection_user_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL
);


--
-- Name: context_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    description text DEFAULT ''::text,
    hint text DEFAULT ''::text,
    label text DEFAULT ''::text,
    context_id character varying NOT NULL,
    meta_key_id character varying NOT NULL,
    is_required boolean DEFAULT false NOT NULL,
    length_max integer,
    length_min integer,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    admin_comment text,
    text_element text_element
);


--
-- Name: contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contexts (
    id character varying NOT NULL,
    label character varying DEFAULT ''::character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    admin_comment text,
    CONSTRAINT context_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_]+$'::text))
);


--
-- Name: custom_urls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_urls (
    id character varying NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    creator_id uuid NOT NULL,
    updator_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    CONSTRAINT custom_url_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL)))),
    CONSTRAINT custom_urls_id_format CHECK (((id)::text ~ '^[a-z][a-z0-9\-\_]+$'::text)),
    CONSTRAINT custom_urls_id_is_not_uuid CHECK ((NOT ((id)::text ~* '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'::text)))
);


--
-- Name: edit_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE edit_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    CONSTRAINT edit_sessions_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL))))
);


--
-- Name: favorite_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favorite_collections (
    user_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: favorite_filter_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favorite_filter_sets (
    user_id uuid NOT NULL,
    filter_set_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: favorite_media_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favorite_media_entries (
    user_id uuid NOT NULL,
    media_entry_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE filter_set_api_client_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_filter boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE filter_set_group_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE filter_set_user_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_filter boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE filter_sets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    definition jsonb DEFAULT '{}'::jsonb NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL
);


--
-- Name: full_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE full_texts (
    media_resource_id uuid NOT NULL,
    text text
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    previous_id integer,
    name character varying,
    institutional_group_id character varying,
    institutional_group_name character varying,
    type character varying DEFAULT 'Group'::character varying NOT NULL,
    searchable text DEFAULT ''::text NOT NULL
);


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE groups_users (
    group_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: io_interfaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE io_interfaces (
    id character varying NOT NULL,
    description character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: io_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE io_mappings (
    io_interface_id character varying NOT NULL,
    meta_key_id character varying NOT NULL,
    key_map character varying,
    key_map_type character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE keywords (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    term character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid,
    meta_key_id character varying NOT NULL
);


--
-- Name: license_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE license_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    "position" double precision,
    parent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: licenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE licenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    is_default boolean DEFAULT false,
    is_custom boolean DEFAULT false,
    label character varying,
    usage character varying,
    url character varying,
    "position" double precision,
    searchable text DEFAULT ''::text NOT NULL
);


--
-- Name: licenses_license_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE licenses_license_groups (
    license_id uuid,
    license_group_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    is_published boolean DEFAULT false
);


--
-- Name: media_entry_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_entry_api_client_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entry_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_entry_group_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    edit_metadata boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entry_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_entry_user_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    edit_metadata boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_files (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    height integer,
    size bigint,
    width integer,
    access_hash text,
    meta_data text,
    content_type character varying NOT NULL,
    filename character varying,
    guid character varying,
    extension character varying,
    media_type character varying,
    media_entry_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    uploader_id uuid NOT NULL
);


--
-- Name: media_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_resources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    previous_id integer,
    download boolean DEFAULT false NOT NULL,
    edit boolean DEFAULT false NOT NULL,
    manage boolean DEFAULT false NOT NULL,
    view boolean DEFAULT false NOT NULL,
    type character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT edit_on_publicpermissions_is_false CHECK ((edit = false)),
    CONSTRAINT manage_on_publicpermissions_is_false CHECK ((manage = false))
);


--
-- Name: meta_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    meta_key_id character varying NOT NULL,
    type character varying,
    string text,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    created_by_id uuid,
    CONSTRAINT check_valid_type CHECK (((type)::text = ANY ((ARRAY['MetaDatum::Licenses'::character varying, 'MetaDatum::Text'::character varying, 'MetaDatum::TextDate'::character varying, 'MetaDatum::Groups'::character varying, 'MetaDatum::Keywords'::character varying, 'MetaDatum::Vocables'::character varying, 'MetaDatum::People'::character varying, 'MetaDatum::Users'::character varying])::text[]))),
    CONSTRAINT meta_data_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL))))
);


--
-- Name: meta_data_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data_groups (
    meta_datum_id uuid NOT NULL,
    group_id uuid NOT NULL,
    created_by_id uuid
);


--
-- Name: meta_data_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data_keywords (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_by_id uuid,
    meta_datum_id uuid NOT NULL,
    keyword_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: meta_data_licenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data_licenses (
    meta_datum_id uuid NOT NULL,
    license_id uuid NOT NULL,
    created_by_id uuid
);


--
-- Name: meta_data_meta_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data_meta_terms (
    meta_datum_id uuid NOT NULL,
    meta_term_id uuid NOT NULL
);


--
-- Name: meta_data_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_data_people (
    meta_datum_id uuid NOT NULL,
    person_id uuid NOT NULL,
    created_by_id uuid
);


--
-- Name: meta_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meta_keys (
    id character varying NOT NULL,
    is_extensible_list boolean DEFAULT false NOT NULL,
    meta_datum_object_type text DEFAULT 'MetaDatum::Text'::text NOT NULL,
    keywords_alphabetical_order boolean DEFAULT true NOT NULL,
    label text,
    description text,
    hint text,
    "position" integer DEFAULT 0 NOT NULL,
    is_enabled_for_media_entries boolean DEFAULT false NOT NULL,
    is_enabled_for_collections boolean DEFAULT false NOT NULL,
    is_enabled_for_filter_sets boolean DEFAULT false NOT NULL,
    vocabulary_id character varying NOT NULL,
    is_extensible boolean DEFAULT false NOT NULL,
    admin_comment text,
    CONSTRAINT check_valid_meta_datum_object_type CHECK ((meta_datum_object_type = ANY (ARRAY['MetaDatum::Licenses'::text, 'MetaDatum::Text'::text, 'MetaDatum::TextDate'::text, 'MetaDatum::Groups'::text, 'MetaDatum::Keywords'::text, 'MetaDatum::Vocables'::text, 'MetaDatum::People'::text, 'MetaDatum::Users'::text]))),
    CONSTRAINT meta_key_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_\:]+$'::text)),
    CONSTRAINT start_id_like_vocabulary_id CHECK (((id)::text ~~ ((vocabulary_id)::text || ':%'::text)))
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    is_bunch boolean DEFAULT false,
    date_of_birth date,
    date_of_death date,
    first_name character varying,
    last_name character varying,
    pseudonym character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    searchable text DEFAULT ''::text NOT NULL
);


--
-- Name: previews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE previews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    media_file_id uuid NOT NULL,
    height integer,
    width integer,
    content_type character varying,
    filename character varying,
    thumbnail character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_type character varying NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: usage_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE usage_terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying,
    version character varying,
    intro text,
    body text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    previous_id integer,
    email character varying,
    login text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    password_digest character varying,
    person_id uuid NOT NULL,
    zhdkid integer,
    trgm_searchable text DEFAULT ''::text NOT NULL,
    autocomplete text DEFAULT ''::text NOT NULL,
    contrast_mode boolean DEFAULT false NOT NULL,
    searchable text DEFAULT ''::text NOT NULL,
    accepted_usage_terms_id uuid,
    CONSTRAINT users_login_simple CHECK ((login ~* '^[a-z0-9\.\-\_]+$'::text))
);


--
-- Name: visualizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE visualizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    resource_identifier character varying NOT NULL,
    control_settings text,
    layout text
);


--
-- Name: vocabularies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE vocabularies (
    id character varying NOT NULL,
    label text,
    description text,
    enabled_for_public_view boolean DEFAULT true NOT NULL,
    enabled_for_public_use boolean DEFAULT true NOT NULL,
    admin_comment text,
    "position" integer,
    CONSTRAINT vocabulary_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_]+$'::text))
);


--
-- Name: vocabulary_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE vocabulary_api_client_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    api_client_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vocabulary_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE vocabulary_group_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vocabulary_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE vocabulary_user_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vw_media_resources; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_media_resources AS
 SELECT media_entries.id,
    media_entries.get_metadata_and_previews,
    media_entries.responsible_user_id,
    media_entries.creator_id,
    media_entries.created_at,
    media_entries.updated_at,
    'MediaEntry'::text AS type
   FROM media_entries
UNION
 SELECT collections.id,
    collections.get_metadata_and_previews,
    collections.responsible_user_id,
    collections.creator_id,
    collections.created_at,
    collections.updated_at,
    'Collection'::text AS type
   FROM collections
UNION
 SELECT filter_sets.id,
    filter_sets.get_metadata_and_previews,
    filter_sets.responsible_user_id,
    filter_sets.creator_id,
    filter_sets.created_at,
    filter_sets.updated_at,
    'FilterSet'::text AS type
   FROM filter_sets;


--
-- Name: zencoder_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE zencoder_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    media_file_id uuid NOT NULL,
    zencoder_id integer,
    comment text,
    state character varying DEFAULT 'initialized'::character varying NOT NULL,
    error text,
    notification text,
    request text,
    response text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: api_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY api_clients
    ADD CONSTRAINT api_clients_pkey PRIMARY KEY (id);


--
-- Name: app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (id);


--
-- Name: collection_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_api_client_permissions
    ADD CONSTRAINT collection_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: collection_collection_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_collection_arcs
    ADD CONSTRAINT collection_collection_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_filter_set_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_filter_set_arcs
    ADD CONSTRAINT collection_filter_set_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_group_permissions
    ADD CONSTRAINT collection_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: collection_media_entry_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_media_entry_arcs
    ADD CONSTRAINT collection_media_entry_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_user_permissions
    ADD CONSTRAINT collection_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contexts
    ADD CONSTRAINT contexts_pkey PRIMARY KEY (id);


--
-- Name: copyrights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY licenses
    ADD CONSTRAINT copyrights_pkey PRIMARY KEY (id);


--
-- Name: custom_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT custom_urls_pkey PRIMARY KEY (id);


--
-- Name: edit_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY edit_sessions
    ADD CONSTRAINT edit_sessions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_api_client_permissions
    ADD CONSTRAINT filter_set_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_group_permissions
    ADD CONSTRAINT filter_set_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_user_permissions
    ADD CONSTRAINT filter_set_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_sets
    ADD CONSTRAINT filter_sets_pkey PRIMARY KEY (id);


--
-- Name: full_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY full_texts
    ADD CONSTRAINT full_texts_pkey PRIMARY KEY (media_resource_id);


--
-- Name: groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: io_interfaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY io_interfaces
    ADD CONSTRAINT io_interfaces_pkey PRIMARY KEY (id);


--
-- Name: io_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY io_mappings
    ADD CONSTRAINT io_mappings_pkey PRIMARY KEY (id);


--
-- Name: keyword_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY keywords
    ADD CONSTRAINT keyword_terms_pkey PRIMARY KEY (id);


--
-- Name: keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (id);


--
-- Name: license_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY license_groups
    ADD CONSTRAINT license_groups_pkey PRIMARY KEY (id);


--
-- Name: media_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entries
    ADD CONSTRAINT media_entries_pkey PRIMARY KEY (id);


--
-- Name: media_entry_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_api_client_permissions
    ADD CONSTRAINT media_entry_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_entry_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_group_permissions
    ADD CONSTRAINT media_entry_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_entry_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_user_permissions
    ADD CONSTRAINT media_entry_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_files
    ADD CONSTRAINT media_files_pkey PRIMARY KEY (id);


--
-- Name: media_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_resources
    ADD CONSTRAINT media_resources_pkey PRIMARY KEY (id);


--
-- Name: meta_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT meta_data_pkey PRIMARY KEY (id);


--
-- Name: meta_key_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_keys
    ADD CONSTRAINT meta_key_definitions_pkey PRIMARY KEY (id);


--
-- Name: meta_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_keys
    ADD CONSTRAINT meta_keys_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: previews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY previews
    ADD CONSTRAINT previews_pkey PRIMARY KEY (id);


--
-- Name: usage_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usage_terms
    ADD CONSTRAINT usage_terms_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visualizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visualizations
    ADD CONSTRAINT visualizations_pkey PRIMARY KEY (id);


--
-- Name: vocabularies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabularies
    ADD CONSTRAINT vocabularies_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_api_client_permissions
    ADD CONSTRAINT vocabulary_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_group_permissions
    ADD CONSTRAINT vocabulary_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_user_permissions
    ADD CONSTRAINT vocabulary_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: zencoder_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zencoder_jobs
    ADD CONSTRAINT zencoder_jobs_pkey PRIMARY KEY (id);


--
-- Name: full_texts_text_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX full_texts_text_idx ON full_texts USING gin (text gin_trgm_ops);


--
-- Name: full_texts_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX full_texts_to_tsvector_idx ON full_texts USING gin (to_tsvector('english'::regconfig, text));


--
-- Name: groups_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_searchable_idx ON groups USING gin (searchable gin_trgm_ops);


--
-- Name: groups_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_to_tsvector_idx ON groups USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: idx_colgrpp_edit_mdata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colgrpp_edit_mdata_and_relations ON collection_group_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_colgrpp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colgrpp_get_mdata_and_previews ON collection_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_colgrpp_on_collection_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_colgrpp_on_collection_id_and_group_id ON collection_group_permissions USING btree (collection_id, group_id);


--
-- Name: idx_colgrpp_on_filter_set_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_colgrpp_on_filter_set_id_and_group_id ON filter_set_group_permissions USING btree (filter_set_id, group_id);


--
-- Name: idx_collapiclp_edit_mdata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collapiclp_edit_mdata_and_relations ON collection_api_client_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_collapiclp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collapiclp_get_mdata_and_previews ON collection_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_collapiclp_on_collection_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_collapiclp_on_collection_id_and_api_client_id ON collection_api_client_permissions USING btree (collection_id, api_client_id);


--
-- Name: idx_collection_user_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_collection_user_permission ON collection_user_permissions USING btree (collection_id, user_id);


--
-- Name: idx_colluserperm_edit_metadata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_edit_metadata_and_relations ON collection_user_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_colluserperm_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_edit_permissions ON collection_user_permissions USING btree (edit_permissions);


--
-- Name: idx_colluserperm_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_get_metadata_and_previews ON collection_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_fsetapiclp_edit_mdata_and_filter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fsetapiclp_edit_mdata_and_filter ON filter_set_api_client_permissions USING btree (edit_metadata_and_filter);


--
-- Name: idx_fsetapiclp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fsetapiclp_get_mdata_and_previews ON filter_set_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_fsetapiclp_on_filter_set_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fsetapiclp_on_filter_set_id_and_api_client_id ON filter_set_api_client_permissions USING btree (filter_set_id, api_client_id);


--
-- Name: idx_fsetusrp_on_filter_set_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fsetusrp_on_filter_set_id_and_user_id ON filter_set_user_permissions USING btree (filter_set_id, user_id);


--
-- Name: idx_me_apicl_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_me_apicl_get_mdata_and_previews ON media_entry_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_media_entry_user_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_media_entry_user_permission ON media_entry_user_permissions USING btree (media_entry_id, user_id);


--
-- Name: idx_megrpp_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_megrpp_get_full_size ON media_entry_api_client_permissions USING btree (get_full_size);


--
-- Name: idx_megrpp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_megrpp_get_mdata_and_previews ON media_entry_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_megrpp_on_media_entry_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_megrpp_on_media_entry_id_and_api_client_id ON media_entry_api_client_permissions USING btree (media_entry_id, api_client_id);


--
-- Name: idx_megrpp_on_media_entry_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_megrpp_on_media_entry_id_and_group_id ON media_entry_group_permissions USING btree (media_entry_id, group_id);


--
-- Name: idx_vocabulary_api_client; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_api_client ON vocabulary_api_client_permissions USING btree (api_client_id, vocabulary_id);


--
-- Name: idx_vocabulary_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_group ON vocabulary_group_permissions USING btree (group_id, vocabulary_id);


--
-- Name: idx_vocabulary_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_user ON vocabulary_user_permissions USING btree (user_id, vocabulary_id);


--
-- Name: index_admins_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admins_on_user_id ON admins USING btree (user_id);


--
-- Name: index_api_clients_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_clients_on_login ON api_clients USING btree (login);


--
-- Name: index_collection_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_api_client_id ON collection_api_client_permissions USING btree (api_client_id);


--
-- Name: index_collection_api_client_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_collection_id ON collection_api_client_permissions USING btree (collection_id);


--
-- Name: index_collection_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_updator_id ON collection_api_client_permissions USING btree (updator_id);


--
-- Name: index_collection_collection_arcs_on_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_child_id ON collection_collection_arcs USING btree (child_id);


--
-- Name: index_collection_collection_arcs_on_child_id_and_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_child_id_and_parent_id ON collection_collection_arcs USING btree (child_id, parent_id);


--
-- Name: index_collection_collection_arcs_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_parent_id ON collection_collection_arcs USING btree (parent_id);


--
-- Name: index_collection_collection_arcs_on_parent_id_and_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_collection_arcs_on_parent_id_and_child_id ON collection_collection_arcs USING btree (parent_id, child_id);


--
-- Name: index_collection_filter_set_arcs_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_collection_id ON collection_filter_set_arcs USING btree (collection_id);


--
-- Name: index_collection_filter_set_arcs_on_collection_id_and_filter_se; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_filter_set_arcs_on_collection_id_and_filter_se ON collection_filter_set_arcs USING btree (collection_id, filter_set_id);


--
-- Name: index_collection_filter_set_arcs_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_filter_set_id ON collection_filter_set_arcs USING btree (filter_set_id);


--
-- Name: index_collection_filter_set_arcs_on_filter_set_id_and_collectio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_filter_set_id_and_collectio ON collection_filter_set_arcs USING btree (filter_set_id, collection_id);


--
-- Name: index_collection_group_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_collection_id ON collection_group_permissions USING btree (collection_id);


--
-- Name: index_collection_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_group_id ON collection_group_permissions USING btree (group_id);


--
-- Name: index_collection_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_updator_id ON collection_group_permissions USING btree (updator_id);


--
-- Name: index_collection_media_entry_arcs_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_collection_id ON collection_media_entry_arcs USING btree (collection_id);


--
-- Name: index_collection_media_entry_arcs_on_collection_id_and_media_en; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_media_entry_arcs_on_collection_id_and_media_en ON collection_media_entry_arcs USING btree (collection_id, media_entry_id);


--
-- Name: index_collection_media_entry_arcs_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_media_entry_id ON collection_media_entry_arcs USING btree (media_entry_id);


--
-- Name: index_collection_media_entry_arcs_on_media_entry_id_and_collect; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_media_entry_id_and_collect ON collection_media_entry_arcs USING btree (media_entry_id, collection_id);


--
-- Name: index_collection_user_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_collection_id ON collection_user_permissions USING btree (collection_id);


--
-- Name: index_collection_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_updator_id ON collection_user_permissions USING btree (updator_id);


--
-- Name: index_collection_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_user_id ON collection_user_permissions USING btree (user_id);


--
-- Name: index_collections_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_created_at ON collections USING btree (created_at);


--
-- Name: index_collections_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_creator_id ON collections USING btree (creator_id);


--
-- Name: index_collections_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_responsible_user_id ON collections USING btree (responsible_user_id);


--
-- Name: index_collections_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_updated_at ON collections USING btree (updated_at);


--
-- Name: index_context_keys_on_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_keys_on_context_id ON context_keys USING btree (context_id);


--
-- Name: index_context_keys_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_keys_on_meta_key_id ON context_keys USING btree (meta_key_id);


--
-- Name: index_custom_urls_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_urls_on_creator_id ON custom_urls USING btree (creator_id);


--
-- Name: index_custom_urls_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_urls_on_updator_id ON custom_urls USING btree (updator_id);


--
-- Name: index_edit_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_edit_sessions_on_user_id ON edit_sessions USING btree (user_id);


--
-- Name: index_favorite_collections_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_collections_on_collection_id ON favorite_collections USING btree (collection_id);


--
-- Name: index_favorite_collections_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_collections_on_user_id ON favorite_collections USING btree (user_id);


--
-- Name: index_favorite_collections_on_user_id_and_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_collections_on_user_id_and_collection_id ON favorite_collections USING btree (user_id, collection_id);


--
-- Name: index_favorite_filter_sets_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_filter_sets_on_filter_set_id ON favorite_filter_sets USING btree (filter_set_id);


--
-- Name: index_favorite_filter_sets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_filter_sets_on_user_id ON favorite_filter_sets USING btree (user_id);


--
-- Name: index_favorite_filter_sets_on_user_id_and_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_filter_sets_on_user_id_and_filter_set_id ON favorite_filter_sets USING btree (user_id, filter_set_id);


--
-- Name: index_favorite_media_entries_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_media_entries_on_media_entry_id ON favorite_media_entries USING btree (media_entry_id);


--
-- Name: index_favorite_media_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_media_entries_on_user_id ON favorite_media_entries USING btree (user_id);


--
-- Name: index_favorite_media_entries_on_user_id_and_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_media_entries_on_user_id_and_media_entry_id ON favorite_media_entries USING btree (user_id, media_entry_id);


--
-- Name: index_filter_set_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_api_client_id ON filter_set_api_client_permissions USING btree (api_client_id);


--
-- Name: index_filter_set_api_client_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_filter_set_id ON filter_set_api_client_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_updator_id ON filter_set_api_client_permissions USING btree (updator_id);


--
-- Name: index_filter_set_group_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_filter_set_id ON filter_set_group_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_group_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_get_metadata_and_previews ON filter_set_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_filter_set_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_group_id ON filter_set_group_permissions USING btree (group_id);


--
-- Name: index_filter_set_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_updator_id ON filter_set_group_permissions USING btree (updator_id);


--
-- Name: index_filter_set_user_permissions_on_edit_metadata_and_filter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_edit_metadata_and_filter ON filter_set_user_permissions USING btree (edit_metadata_and_filter);


--
-- Name: index_filter_set_user_permissions_on_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_edit_permissions ON filter_set_user_permissions USING btree (edit_permissions);


--
-- Name: index_filter_set_user_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_filter_set_id ON filter_set_user_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_user_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_get_metadata_and_previews ON filter_set_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_filter_set_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_updator_id ON filter_set_user_permissions USING btree (updator_id);


--
-- Name: index_filter_set_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_user_id ON filter_set_user_permissions USING btree (user_id);


--
-- Name: index_filter_sets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_created_at ON filter_sets USING btree (created_at);


--
-- Name: index_filter_sets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_creator_id ON filter_sets USING btree (creator_id);


--
-- Name: index_filter_sets_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_responsible_user_id ON filter_sets USING btree (responsible_user_id);


--
-- Name: index_filter_sets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_updated_at ON filter_sets USING btree (updated_at);


--
-- Name: index_groups_on_institutional_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_institutional_group_id ON groups USING btree (institutional_group_id);


--
-- Name: index_groups_on_institutional_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_institutional_group_name ON groups USING btree (institutional_group_name);


--
-- Name: index_groups_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_name ON groups USING btree (name);


--
-- Name: index_groups_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_type ON groups USING btree (type);


--
-- Name: index_groups_users_on_group_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_users_on_group_id_and_user_id ON groups_users USING btree (group_id, user_id);


--
-- Name: index_groups_users_on_user_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_users_on_user_id_and_group_id ON groups_users USING btree (user_id, group_id);


--
-- Name: index_keywords_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keywords_on_meta_key_id ON keywords USING btree (meta_key_id);


--
-- Name: index_licenses_on_label; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_licenses_on_label ON licenses USING btree (label);


--
-- Name: index_licenses_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_licenses_on_url ON licenses USING btree (url);


--
-- Name: index_md_groups_on_md_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_groups_on_md_id_and_group_id ON meta_data_groups USING btree (meta_datum_id, group_id);


--
-- Name: index_md_licenses_on_md_id_and_license_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_licenses_on_md_id_and_license_id ON meta_data_licenses USING btree (meta_datum_id, license_id);


--
-- Name: index_md_people_on_md_id_and_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_people_on_md_id_and_person_id ON meta_data_people USING btree (meta_datum_id, person_id);


--
-- Name: index_md_users_on_md_id_and_keyword_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_users_on_md_id_and_keyword_id ON meta_data_keywords USING btree (meta_datum_id, keyword_id);


--
-- Name: index_media_entries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_created_at ON media_entries USING btree (created_at);


--
-- Name: index_media_entries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_creator_id ON media_entries USING btree (creator_id);


--
-- Name: index_media_entries_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_responsible_user_id ON media_entries USING btree (responsible_user_id);


--
-- Name: index_media_entries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_updated_at ON media_entries USING btree (updated_at);


--
-- Name: index_media_entry_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_api_client_id ON media_entry_api_client_permissions USING btree (api_client_id);


--
-- Name: index_media_entry_api_client_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_get_full_size ON media_entry_api_client_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_api_client_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_media_entry_id ON media_entry_api_client_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_updator_id ON media_entry_api_client_permissions USING btree (updator_id);


--
-- Name: index_media_entry_group_permissions_on_edit_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_edit_metadata ON media_entry_group_permissions USING btree (edit_metadata);


--
-- Name: index_media_entry_group_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_get_full_size ON media_entry_group_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_group_id ON media_entry_group_permissions USING btree (group_id);


--
-- Name: index_media_entry_group_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_media_entry_id ON media_entry_group_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_updator_id ON media_entry_group_permissions USING btree (updator_id);


--
-- Name: index_media_entry_user_permissions_on_edit_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_edit_metadata ON media_entry_user_permissions USING btree (edit_metadata);


--
-- Name: index_media_entry_user_permissions_on_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_edit_permissions ON media_entry_user_permissions USING btree (edit_permissions);


--
-- Name: index_media_entry_user_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_get_full_size ON media_entry_user_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_user_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_get_metadata_and_previews ON media_entry_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_media_entry_user_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_media_entry_id ON media_entry_user_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_updator_id ON media_entry_user_permissions USING btree (updator_id);


--
-- Name: index_media_entry_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_user_id ON media_entry_user_permissions USING btree (user_id);


--
-- Name: index_media_files_on_extension; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_extension ON media_files USING btree (extension);


--
-- Name: index_media_files_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_media_entry_id ON media_files USING btree (media_entry_id);


--
-- Name: index_media_files_on_media_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_media_type ON media_files USING btree (media_type);


--
-- Name: index_media_resources_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_resources_on_created_at ON media_resources USING btree (created_at);


--
-- Name: index_media_resources_on_previous_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_resources_on_previous_id ON media_resources USING btree (previous_id);


--
-- Name: index_media_resources_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_resources_on_type ON media_resources USING btree (type);


--
-- Name: index_media_resources_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_resources_on_updated_at ON media_resources USING btree (updated_at);


--
-- Name: index_meta_data_keywords_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_created_at ON meta_data_keywords USING btree (created_at);


--
-- Name: index_meta_data_keywords_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_created_by_id ON meta_data_keywords USING btree (created_by_id);


--
-- Name: index_meta_data_keywords_on_keyword_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_keyword_id ON meta_data_keywords USING btree (keyword_id);


--
-- Name: index_meta_data_keywords_on_meta_datum_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_meta_datum_id ON meta_data_keywords USING btree (meta_datum_id);


--
-- Name: index_meta_data_meta_terms_on_meta_datum_id_and_meta_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_meta_terms_on_meta_datum_id_and_meta_term_id ON meta_data_meta_terms USING btree (meta_datum_id, meta_term_id);


--
-- Name: index_meta_data_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_collection_id ON meta_data USING btree (collection_id);


--
-- Name: index_meta_data_on_collection_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_collection_id_and_meta_key_id ON meta_data USING btree (collection_id, meta_key_id);


--
-- Name: index_meta_data_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_filter_set_id ON meta_data USING btree (filter_set_id);


--
-- Name: index_meta_data_on_filter_set_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_filter_set_id_and_meta_key_id ON meta_data USING btree (filter_set_id, meta_key_id);


--
-- Name: index_meta_data_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_media_entry_id ON meta_data USING btree (media_entry_id);


--
-- Name: index_meta_data_on_media_entry_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_media_entry_id_and_meta_key_id ON meta_data USING btree (media_entry_id, meta_key_id);


--
-- Name: index_meta_data_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_meta_key_id ON meta_data USING btree (meta_key_id);


--
-- Name: index_meta_data_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_type ON meta_data USING btree (type);


--
-- Name: index_people_on_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_first_name ON people USING btree (first_name);


--
-- Name: index_people_on_is_bunch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_is_bunch ON people USING btree (is_bunch);


--
-- Name: index_people_on_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_last_name ON people USING btree (last_name);


--
-- Name: index_previews_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_created_at ON previews USING btree (created_at);


--
-- Name: index_previews_on_media_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_media_file_id ON previews USING btree (media_file_id);


--
-- Name: index_previews_on_media_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_media_type ON previews USING btree (media_type);


--
-- Name: index_users_on_autocomplete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_autocomplete ON users USING btree (autocomplete);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: index_users_on_zhdkid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_zhdkid ON users USING btree (zhdkid);


--
-- Name: index_vocabularies_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vocabularies_on_position ON vocabularies USING btree ("position");


--
-- Name: index_zencoder_jobs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_created_at ON zencoder_jobs USING btree (created_at);


--
-- Name: index_zencoder_jobs_on_media_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_media_file_id ON zencoder_jobs USING btree (media_file_id);


--
-- Name: keyword_terms_term_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX keyword_terms_term_idx ON keywords USING gin (term gin_trgm_ops);


--
-- Name: keyword_terms_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX keyword_terms_to_tsvector_idx ON keywords USING gin (to_tsvector('english'::regconfig, (term)::text));


--
-- Name: licenses_label_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX licenses_label_idx ON licenses USING gin (label gin_trgm_ops);


--
-- Name: licenses_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX licenses_searchable_idx ON licenses USING gin (searchable gin_trgm_ops);


--
-- Name: licenses_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX licenses_to_tsvector_idx ON licenses USING gin (to_tsvector('english'::regconfig, (label)::text));


--
-- Name: licenses_to_tsvector_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX licenses_to_tsvector_idx1 ON licenses USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: meta_data_string_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meta_data_string_idx ON meta_data USING gin (string gin_trgm_ops);


--
-- Name: meta_data_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meta_data_to_tsvector_idx ON meta_data USING gin (to_tsvector('english'::regconfig, string));


--
-- Name: people_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_searchable_idx ON people USING gin (searchable gin_trgm_ops);


--
-- Name: people_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_to_tsvector_idx ON people USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: users_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_searchable_idx ON users USING gin (searchable gin_trgm_ops);


--
-- Name: users_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_to_tsvector_idx ON users USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: users_trgm_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_trgm_searchable_idx ON users USING gin (trgm_searchable gin_trgm_ops);


--
-- Name: trigger_check_collection_cover_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_collection_cover_uniqueness AFTER INSERT OR UPDATE ON collection_media_entry_arcs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_collection_cover_uniqueness();


--
-- Name: trigger_check_collection_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_collection_primary_uniqueness AFTER INSERT OR UPDATE ON custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_collection_primary_uniqueness();


--
-- Name: trigger_check_filter_set_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_filter_set_primary_uniqueness AFTER INSERT OR UPDATE ON custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_filter_set_primary_uniqueness();


--
-- Name: trigger_check_media_entry_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_media_entry_primary_uniqueness AFTER INSERT OR UPDATE ON custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_media_entry_primary_uniqueness();


--
-- Name: trigger_check_users_apiclients_login_uniqueness_on_apiclients; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_users_apiclients_login_uniqueness_on_apiclients AFTER INSERT OR UPDATE ON api_clients DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_users_apiclients_login_uniqueness();


--
-- Name: trigger_check_users_apiclients_login_uniqueness_on_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_users_apiclients_login_uniqueness_on_users AFTER INSERT OR UPDATE ON users DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_users_apiclients_login_uniqueness();


--
-- Name: trigger_collection_may_not_be_its_own_parent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_collection_may_not_be_its_own_parent AFTER INSERT OR UPDATE ON collection_collection_arcs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE collection_may_not_be_its_own_parent();


--
-- Name: trigger_delete_empty_meta_data_groups_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_groups_after_delete_join AFTER DELETE ON meta_data_groups DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE delete_empty_meta_data_groups_after_delete_join();


--
-- Name: trigger_delete_empty_meta_data_groups_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_groups_after_insert AFTER INSERT ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Groups'::text)) EXECUTE PROCEDURE delete_empty_meta_data_groups_after_insert();


--
-- Name: trigger_delete_empty_meta_data_keywords_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_keywords_after_delete_join AFTER DELETE ON meta_data_keywords DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE delete_empty_meta_data_keywords_after_delete_join();


--
-- Name: trigger_delete_empty_meta_data_keywords_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_keywords_after_insert AFTER INSERT ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Keywords'::text)) EXECUTE PROCEDURE delete_empty_meta_data_keywords_after_insert();


--
-- Name: trigger_delete_empty_meta_data_licenses_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_licenses_after_delete_join AFTER DELETE ON meta_data_licenses DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE delete_empty_meta_data_licenses_after_delete_join();


--
-- Name: trigger_delete_empty_meta_data_licenses_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_licenses_after_insert AFTER INSERT ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Licenses'::text)) EXECUTE PROCEDURE delete_empty_meta_data_licenses_after_insert();


--
-- Name: trigger_delete_empty_meta_data_people_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_people_after_delete_join AFTER DELETE ON meta_data_people DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE delete_empty_meta_data_people_after_delete_join();


--
-- Name: trigger_delete_empty_meta_data_people_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_people_after_insert AFTER INSERT ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::People'::text)) EXECUTE PROCEDURE delete_empty_meta_data_people_after_insert();


--
-- Name: trigger_delete_meta_datum_text_string_null; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_meta_datum_text_string_null AFTER INSERT OR UPDATE ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE delete_meta_datum_text_string_null();


--
-- Name: trigger_madek_core_meta_key_immutability; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_madek_core_meta_key_immutability AFTER INSERT OR DELETE OR UPDATE ON meta_keys DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_madek_core_meta_key_immutability();


--
-- Name: trigger_meta_data_meta_key_type_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_meta_data_meta_key_type_consistency AFTER INSERT OR UPDATE ON meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_meta_data_meta_key_type_consistency();


--
-- Name: trigger_meta_key_meta_data_type_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_meta_key_meta_data_type_consistency AFTER INSERT OR UPDATE ON meta_keys DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE check_meta_key_meta_data_type_consistency();


--
-- Name: update_searchable_column_of_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_groups BEFORE INSERT OR UPDATE ON groups FOR EACH ROW EXECUTE PROCEDURE groups_update_searchable_column();


--
-- Name: update_searchable_column_of_licenses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_licenses BEFORE INSERT OR UPDATE ON licenses FOR EACH ROW EXECUTE PROCEDURE licenses_update_searchable_column();


--
-- Name: update_searchable_column_of_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_people BEFORE INSERT OR UPDATE ON people FOR EACH ROW EXECUTE PROCEDURE people_update_searchable_column();


--
-- Name: update_searchable_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_users BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE users_update_searchable_column();


--
-- Name: update_updated_at_column_of_admins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_admins BEFORE UPDATE ON admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_api_clients; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_api_clients BEFORE UPDATE ON api_clients FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_app_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_app_settings BEFORE UPDATE ON app_settings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_collection_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_api_client_permissions BEFORE UPDATE ON collection_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_collection_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_group_permissions BEFORE UPDATE ON collection_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_collection_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_user_permissions BEFORE UPDATE ON collection_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collections BEFORE UPDATE ON collections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_context_keys; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_context_keys BEFORE UPDATE ON context_keys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_custom_urls; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_custom_urls BEFORE UPDATE ON custom_urls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_edit_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_edit_sessions BEFORE UPDATE ON edit_sessions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_favorite_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_collections BEFORE UPDATE ON favorite_collections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_favorite_filter_sets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_filter_sets BEFORE UPDATE ON favorite_filter_sets FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_favorite_media_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_media_entries BEFORE UPDATE ON favorite_media_entries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_filter_set_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_api_client_permissions BEFORE UPDATE ON filter_set_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_filter_set_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_group_permissions BEFORE UPDATE ON filter_set_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_filter_set_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_user_permissions BEFORE UPDATE ON filter_set_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_filter_sets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_sets BEFORE UPDATE ON filter_sets FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_io_interfaces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_io_interfaces BEFORE UPDATE ON io_interfaces FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_io_mappings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_io_mappings BEFORE UPDATE ON io_mappings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_keywords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_keywords BEFORE UPDATE ON keywords FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_license_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_license_groups BEFORE UPDATE ON license_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_licenses_license_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_licenses_license_groups BEFORE UPDATE ON licenses_license_groups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entries BEFORE UPDATE ON media_entries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_entry_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_api_client_permissions BEFORE UPDATE ON media_entry_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_entry_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_group_permissions BEFORE UPDATE ON media_entry_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_entry_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_user_permissions BEFORE UPDATE ON media_entry_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_files; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_files BEFORE UPDATE ON media_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_media_resources; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_resources BEFORE UPDATE ON media_resources FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_meta_data_keywords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_meta_data_keywords BEFORE UPDATE ON meta_data_keywords FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_people BEFORE UPDATE ON people FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_previews; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_previews BEFORE UPDATE ON previews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_usage_terms; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_usage_terms BEFORE UPDATE ON usage_terms FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_users BEFORE UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_zencoder_jobs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_zencoder_jobs BEFORE UPDATE ON zencoder_jobs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: admins_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_users_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: app-settings_featured-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_settings
    ADD CONSTRAINT "app-settings_featured-sets_fkey" FOREIGN KEY (featured_set_id) REFERENCES media_resources(id);


--
-- Name: app-settings_splashscreen-slideshow-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY app_settings
    ADD CONSTRAINT "app-settings_splashscreen-slideshow-sets_fkey" FOREIGN KEY (splashscreen_slideshow_set_id) REFERENCES media_resources(id);


--
-- Name: collection-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE;


--
-- Name: collection-api-client-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-api-client-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: collection-collection-arcs_children_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_collection_arcs
    ADD CONSTRAINT "collection-collection-arcs_children_fkey" FOREIGN KEY (child_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-collection-arcs_parents_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_collection_arcs
    ADD CONSTRAINT "collection-collection-arcs_parents_fkey" FOREIGN KEY (parent_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-filter-set-arcs_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_filter_set_arcs
    ADD CONSTRAINT "collection-filter-set-arcs_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-filter-set-arcs_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_filter_set_arcs
    ADD CONSTRAINT "collection-filter-set-arcs_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: collection-group-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_group_permissions
    ADD CONSTRAINT "collection-group-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-group-permissions_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_group_permissions
    ADD CONSTRAINT "collection-group-permissions_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: collection-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_group_permissions
    ADD CONSTRAINT "collection-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: collection-media-entry-arcs_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_media_entry_arcs
    ADD CONSTRAINT "collection-media-entry-arcs_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-media-entry-arcs_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_media_entry_arcs
    ADD CONSTRAINT "collection-media-entry-arcs_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: collection-user-permissions-updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions-updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: collection-user-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: collection-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: collections_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT collections_creators_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: collections_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collections
    ADD CONSTRAINT "collections_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES users(id);


--
-- Name: custom-urls_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT "custom-urls_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: custom-urls_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT "custom-urls_creators_fkey" FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: custom-urls_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT "custom-urls_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: custom-urls_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT "custom-urls_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: custom-urls_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_urls
    ADD CONSTRAINT "custom-urls_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: edit-sessions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY edit_sessions
    ADD CONSTRAINT "edit-sessions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: edit-sessions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY edit_sessions
    ADD CONSTRAINT "edit-sessions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: edit-sessions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY edit_sessions
    ADD CONSTRAINT "edit-sessions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: edit-sessions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY edit_sessions
    ADD CONSTRAINT "edit-sessions_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: favorite-collections_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_collections
    ADD CONSTRAINT "favorite-collections_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: favorite-collections_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_collections
    ADD CONSTRAINT "favorite-collections_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: favorite-filter-sets_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_filter_sets
    ADD CONSTRAINT "favorite-filter-sets_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: favorite-filter-sets_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_filter_sets
    ADD CONSTRAINT "favorite-filter-sets_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: favorite-media-entries_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_media_entries
    ADD CONSTRAINT "favorite-media-entries_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: favorite-media-entries_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorite_media_entries
    ADD CONSTRAINT "favorite-media-entries_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: filter-set-api-client-permissions-updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions-updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: filter-set-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE;


--
-- Name: filter-set-api-client-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter-set-group-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_group_permissions
    ADD CONSTRAINT "filter-set-group-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter-set-group-permissions_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_group_permissions
    ADD CONSTRAINT "filter-set-group-permissions_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: filter-set-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_group_permissions
    ADD CONSTRAINT "filter-set-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: filter-set-user-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter-set-user-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: filter-set-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: filter-sets_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_sets
    ADD CONSTRAINT "filter-sets_creators_fkey" FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: filter-sets_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY filter_sets
    ADD CONSTRAINT "filter-sets_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES users(id);


--
-- Name: fk_rails_2957e036b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_keys
    ADD CONSTRAINT fk_rails_2957e036b5 FOREIGN KEY (meta_key_id) REFERENCES meta_keys(id) ON DELETE CASCADE;


--
-- Name: fk_rails_45043d2037; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY api_clients
    ADD CONSTRAINT fk_rails_45043d2037 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_67eb3c60e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_licenses
    ADD CONSTRAINT fk_rails_67eb3c60e8 FOREIGN KEY (license_id) REFERENCES licenses(id);


--
-- Name: fk_rails_6f33d95dfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_licenses
    ADD CONSTRAINT fk_rails_6f33d95dfc FOREIGN KEY (meta_datum_id) REFERENCES meta_data(id) ON DELETE CASCADE;


--
-- Name: fk_rails_b297363c89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_keys
    ADD CONSTRAINT fk_rails_b297363c89 FOREIGN KEY (context_id) REFERENCES contexts(id);


--
-- Name: full-texts_media-resources_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY full_texts
    ADD CONSTRAINT "full-texts_media-resources_fkey" FOREIGN KEY (media_resource_id) REFERENCES media_resources(id) ON DELETE CASCADE;


--
-- Name: groups-users_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT "groups-users_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: groups-users_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups_users
    ADD CONSTRAINT "groups-users_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: io-mappings_io-interfaces_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY io_mappings
    ADD CONSTRAINT "io-mappings_io-interfaces_fkey" FOREIGN KEY (io_interface_id) REFERENCES io_interfaces(id) ON DELETE CASCADE;


--
-- Name: io-mappings_meta-keys_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY io_mappings
    ADD CONSTRAINT "io-mappings_meta-keys_fkey" FOREIGN KEY (meta_key_id) REFERENCES meta_keys(id) ON DELETE CASCADE;


--
-- Name: keywords_meta-keys_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY keywords
    ADD CONSTRAINT "keywords_meta-keys_fkey" FOREIGN KEY (meta_key_id) REFERENCES meta_keys(id) ON DELETE CASCADE;


--
-- Name: licenses-license-groups_license-groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY licenses_license_groups
    ADD CONSTRAINT "licenses-license-groups_license-groups_fkey" FOREIGN KEY (license_group_id) REFERENCES license_groups(id);


--
-- Name: licenses-license-groups_licenses_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY licenses_license_groups
    ADD CONSTRAINT "licenses-license-groups_licenses_fkey" FOREIGN KEY (license_id) REFERENCES licenses(id);


--
-- Name: media-entries_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entries
    ADD CONSTRAINT "media-entries_creators_fkey" FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: media-entries_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entries
    ADD CONSTRAINT "media-entries_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES users(id);


--
-- Name: media-entry-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE;


--
-- Name: media-entry-api-client-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: media-entry-api-client-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: media-entry-group-permissions_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_group_permissions
    ADD CONSTRAINT "media-entry-group-permissions_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: media-entry-group-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_group_permissions
    ADD CONSTRAINT "media-entry-group-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: media-entry-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_group_permissions
    ADD CONSTRAINT "media-entry-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: media-entry-user-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: media-entry-user-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES users(id);


--
-- Name: media-entry-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: media-files_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_files
    ADD CONSTRAINT "media-files_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id);


--
-- Name: media-files_uploaders_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_files
    ADD CONSTRAINT "media-files_uploaders_fkey" FOREIGN KEY (uploader_id) REFERENCES users(id);


--
-- Name: meta-data-groups_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_groups
    ADD CONSTRAINT "meta-data-groups_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: meta-data-groups_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_groups
    ADD CONSTRAINT "meta-data-groups_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES meta_data(id) ON DELETE CASCADE;


--
-- Name: meta-data-groups_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_groups
    ADD CONSTRAINT "meta-data-groups_users_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: meta-data-keywords_keywords_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_keywords
    ADD CONSTRAINT "meta-data-keywords_keywords_fkey" FOREIGN KEY (keyword_id) REFERENCES keywords(id) ON DELETE CASCADE;


--
-- Name: meta-data-keywords_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_keywords
    ADD CONSTRAINT "meta-data-keywords_users_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: meta-data-licenses_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_licenses
    ADD CONSTRAINT "meta-data-licenses_users_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: meta-data-meta-terms_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_meta_terms
    ADD CONSTRAINT "meta-data-meta-terms_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES meta_data(id) ON DELETE CASCADE;


--
-- Name: meta-data-people_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_people
    ADD CONSTRAINT "meta-data-people_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES meta_data(id) ON DELETE CASCADE;


--
-- Name: meta-data-people_people_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_people
    ADD CONSTRAINT "meta-data-people_people_fkey" FOREIGN KEY (person_id) REFERENCES people(id);


--
-- Name: meta-data-people_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_people
    ADD CONSTRAINT "meta-data-people_users_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: meta-data_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT "meta-data_collections_fkey" FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE;


--
-- Name: meta-data_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT "meta-data_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES filter_sets(id) ON DELETE CASCADE;


--
-- Name: meta-data_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT "meta-data_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES media_entries(id) ON DELETE CASCADE;


--
-- Name: meta-data_meta-keys_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT "meta-data_meta-keys_fkey" FOREIGN KEY (meta_key_id) REFERENCES meta_keys(id) ON DELETE CASCADE;


--
-- Name: meta-data_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data
    ADD CONSTRAINT "meta-data_users_fkey" FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: meta-keys_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_keys
    ADD CONSTRAINT "meta-keys_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES vocabularies(id) ON DELETE CASCADE;


--
-- Name: meta_data_keywords_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meta_data_keywords
    ADD CONSTRAINT "meta_data_keywords_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES meta_data(id) ON DELETE CASCADE;


--
-- Name: parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY license_groups
    ADD CONSTRAINT parent_id_fkey FOREIGN KEY (parent_id) REFERENCES license_groups(id);


--
-- Name: previews_media-files_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY previews
    ADD CONSTRAINT "previews_media-files_fkey" FOREIGN KEY (media_file_id) REFERENCES media_files(id) ON DELETE CASCADE;


--
-- Name: users_people_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_people_fkey FOREIGN KEY (person_id) REFERENCES people(id);


--
-- Name: visualizations_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visualizations
    ADD CONSTRAINT visualizations_users_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: vocabulary-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_api_client_permissions
    ADD CONSTRAINT "vocabulary-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES api_clients(id) ON DELETE CASCADE;


--
-- Name: vocabulary-api-client-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_api_client_permissions
    ADD CONSTRAINT "vocabulary-api-client-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES vocabularies(id) ON DELETE CASCADE;


--
-- Name: vocabulary-group-permissions_groups_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_group_permissions
    ADD CONSTRAINT "vocabulary-group-permissions_groups_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;


--
-- Name: vocabulary-group-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_group_permissions
    ADD CONSTRAINT "vocabulary-group-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES vocabularies(id) ON DELETE CASCADE;


--
-- Name: vocabulary-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_user_permissions
    ADD CONSTRAINT "vocabulary-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: vocabulary-user-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_user_permissions
    ADD CONSTRAINT "vocabulary-user-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES vocabularies(id) ON DELETE CASCADE;


--
-- Name: zencoder-jobs_media-files_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zencoder_jobs
    ADD CONSTRAINT "zencoder-jobs_media-files_fkey" FOREIGN KEY (media_file_id) REFERENCES media_files(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('0');

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('100');

INSERT INTO schema_migrations (version) VALUES ('101');

INSERT INTO schema_migrations (version) VALUES ('102');

INSERT INTO schema_migrations (version) VALUES ('103');

INSERT INTO schema_migrations (version) VALUES ('104');

INSERT INTO schema_migrations (version) VALUES ('105');

INSERT INTO schema_migrations (version) VALUES ('107');

INSERT INTO schema_migrations (version) VALUES ('108');

INSERT INTO schema_migrations (version) VALUES ('109');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('110');

INSERT INTO schema_migrations (version) VALUES ('111');

INSERT INTO schema_migrations (version) VALUES ('112');

INSERT INTO schema_migrations (version) VALUES ('113');

INSERT INTO schema_migrations (version) VALUES ('114');

INSERT INTO schema_migrations (version) VALUES ('115');

INSERT INTO schema_migrations (version) VALUES ('117');

INSERT INTO schema_migrations (version) VALUES ('118');

INSERT INTO schema_migrations (version) VALUES ('119');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('120');

INSERT INTO schema_migrations (version) VALUES ('121');

INSERT INTO schema_migrations (version) VALUES ('122');

INSERT INTO schema_migrations (version) VALUES ('123');

INSERT INTO schema_migrations (version) VALUES ('124');

INSERT INTO schema_migrations (version) VALUES ('125');

INSERT INTO schema_migrations (version) VALUES ('126');

INSERT INTO schema_migrations (version) VALUES ('127');

INSERT INTO schema_migrations (version) VALUES ('128');

INSERT INTO schema_migrations (version) VALUES ('129');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('130');

INSERT INTO schema_migrations (version) VALUES ('131');

INSERT INTO schema_migrations (version) VALUES ('132');

INSERT INTO schema_migrations (version) VALUES ('133');

INSERT INTO schema_migrations (version) VALUES ('134');

INSERT INTO schema_migrations (version) VALUES ('135');

INSERT INTO schema_migrations (version) VALUES ('136');

INSERT INTO schema_migrations (version) VALUES ('137');

INSERT INTO schema_migrations (version) VALUES ('138');

INSERT INTO schema_migrations (version) VALUES ('139');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('140');

INSERT INTO schema_migrations (version) VALUES ('141');

INSERT INTO schema_migrations (version) VALUES ('142');

INSERT INTO schema_migrations (version) VALUES ('143');

INSERT INTO schema_migrations (version) VALUES ('144');

INSERT INTO schema_migrations (version) VALUES ('145');

INSERT INTO schema_migrations (version) VALUES ('146');

INSERT INTO schema_migrations (version) VALUES ('147');

INSERT INTO schema_migrations (version) VALUES ('148');

INSERT INTO schema_migrations (version) VALUES ('149');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('150');

INSERT INTO schema_migrations (version) VALUES ('151');

INSERT INTO schema_migrations (version) VALUES ('152');

INSERT INTO schema_migrations (version) VALUES ('153');

INSERT INTO schema_migrations (version) VALUES ('154');

INSERT INTO schema_migrations (version) VALUES ('156');

INSERT INTO schema_migrations (version) VALUES ('157');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('165');

INSERT INTO schema_migrations (version) VALUES ('166');

INSERT INTO schema_migrations (version) VALUES ('168');

INSERT INTO schema_migrations (version) VALUES ('169');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('171');

INSERT INTO schema_migrations (version) VALUES ('175');

INSERT INTO schema_migrations (version) VALUES ('176');

INSERT INTO schema_migrations (version) VALUES ('177');

INSERT INTO schema_migrations (version) VALUES ('178');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('180');

INSERT INTO schema_migrations (version) VALUES ('181');

INSERT INTO schema_migrations (version) VALUES ('182');

INSERT INTO schema_migrations (version) VALUES ('183');

INSERT INTO schema_migrations (version) VALUES ('184');

INSERT INTO schema_migrations (version) VALUES ('185');

INSERT INTO schema_migrations (version) VALUES ('186');

INSERT INTO schema_migrations (version) VALUES ('187');

INSERT INTO schema_migrations (version) VALUES ('188');

INSERT INTO schema_migrations (version) VALUES ('189');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('190');

INSERT INTO schema_migrations (version) VALUES ('191');

INSERT INTO schema_migrations (version) VALUES ('192');

INSERT INTO schema_migrations (version) VALUES ('193');

INSERT INTO schema_migrations (version) VALUES ('199');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('200');

INSERT INTO schema_migrations (version) VALUES ('201');

INSERT INTO schema_migrations (version) VALUES ('202');

INSERT INTO schema_migrations (version) VALUES ('203');

INSERT INTO schema_migrations (version) VALUES ('204');

INSERT INTO schema_migrations (version) VALUES ('205');

INSERT INTO schema_migrations (version) VALUES ('206');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');

