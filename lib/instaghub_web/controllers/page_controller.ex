defmodule InstaghubWeb.PageController do
  use InstaghubWeb, :controller
  alias Ins.Web.API
  alias Instaghub.RedisUtil
  alias InstaghubWeb.Plug.Cache
  alias InstaghubWeb.SEO
  require Logger

  defp handle_404(conn) do
    conn
    |> Plug.Conn.put_status(404)
    |> Phoenix.Controller.put_view(InstaghubWeb.ErrorView)
    |> Phoenix.Controller.render("404.html", %{})
    |> Plug.Conn.halt
  end

  def not_found(conn, _params) do
    handle_404(conn)
  end

  def index(%Plug.Conn{request_path: path} = conn, _params) do
    cursor = Cache.get_cursor(conn)
    redis_key_md5 = Cache.get_page_key(conn, cursor)
    page = Cache.get_page(conn)
    feeds_with_page =
    if page == nil do
      feeds_with_page = case path do
                          "/" -> API.get_feeds(cursor, :sports)
                          "/explore/women" -> API.get_feeds(cursor, :women)
                          "/explore/women/" -> API.get_feeds(cursor, :women)
                          "/explore/animal" -> API.get_feeds(cursor, :animal)
                          "/explore/animal/" -> API.get_feeds(cursor, :animal)
                          "/explore/game" -> API.get_feeds(cursor, :game)
                          "/explore/game/" -> API.get_feeds(cursor, :game)
                          "/explore/food" -> API.get_feeds(cursor, :food)
                          "/explore/food/" -> API.get_feeds(cursor, :food)
                          "/explore/hot" -> API.get_feeds(cursor, :hot)
                          "/explore/hot/" -> API.get_feeds(cursor, :hot)
                          _ -> API.get_feeds(cursor)
                        end
      if feeds_with_page != nil do
        feeds_bin = :erlang.term_to_binary(feeds_with_page)
        RedisUtil.setx(redis_key_md5, feeds_bin)
        Logger.debug "get page with api and store in redis with key #{redis_key_md5}"
      end
      feeds_with_page
    else
      page
    end
    if feeds_with_page == nil do
      handle_404(conn)
    else
      if cursor == nil do
        render(conn, "index.html", posts: feeds_with_page.posts, page_info: feeds_with_page.page_info, seo: SEO.get_index_seo(path, feeds_with_page))
      else
        conn
        |> put_layout(false)
        |> put_view(InstaghubWeb.HtmlView)
        |> render("posts.html", posts: feeds_with_page.posts, page_info: feeds_with_page.page_info)
      end
    end
  end

  def post_comment(conn, %{"shortcode" => shortcode} = _params) do
    redis_key_md5 = Cache.get_page_key(conn, nil)
    page = Cache.get_page(conn)
    feeds_with_page =
    if page == nil do
      feeds_with_page = API.get_post_comment(shortcode)
      if feeds_with_page != nil do
        feeds_bin = :erlang.term_to_binary(feeds_with_page)
        RedisUtil.setx(redis_key_md5, feeds_bin)
        Logger.debug "get page with api and store in redis with key #{redis_key_md5}"
      end
      feeds_with_page
    else
      page
    end
    if feeds_with_page == nil do
      handle_404(conn)
    else
      render(conn, "post_comment.html", post: feeds_with_page, seo: SEO.get_post_seo(feeds_with_page))
    end
  end

  def user_posts(conn, %{"username" => username} = params) do
    id = Map.get(params, "id")
    cursor = Cache.get_cursor(conn)
    redis_key_md5 = Cache.get_page_key(conn, cursor)
    page = Cache.get_page(conn)
    feeds_with_page =
    if page == nil do
      feeds_with_page = if cursor == nil && id == nil do
        API.get_user_profile(username)
      else
        API.get_user_posts(id, cursor)
      end
      if feeds_with_page != nil do
        feeds_bin   = :erlang.term_to_binary(feeds_with_page)
        RedisUtil.setx(redis_key_md5, feeds_bin)
        Logger.debug "get page with api and store in redis with key #{redis_key_md5}"
      end
      feeds_with_page
    else
      page
    end
    if feeds_with_page == nil do
      handle_404(conn)
    else
      if cursor == nil do
        render(conn, "user.html", posts: feeds_with_page.edge_owner_to_timeline_media.posts, page_info: feeds_with_page.edge_owner_to_timeline_media.page_info, user: feeds_with_page, seo: SEO.get_user_seo(feeds_with_page))
      else
        conn
        |> put_layout(false)
        |> put_view(InstaghubWeb.HtmlView)
        |> render("posts.html", posts: feeds_with_page.posts, page_info: feeds_with_page.page_info)
      end
    end
  end

  def tag_posts(conn, %{"tagname" => tagname} = _params) do
    cursor = Cache.get_cursor(conn)
    redis_key_md5 = Cache.get_page_key(conn, cursor)
    page = Cache.get_page(conn)
    feeds_with_page =
    if page == nil do
      feeds_with_page = API.get_tag_posts(tagname, cursor)
      if feeds_with_page != nil do
        feeds_bin = :erlang.term_to_binary(feeds_with_page)
        RedisUtil.setx(redis_key_md5, feeds_bin)
        Logger.debug "get page with api and store in redis with key #{redis_key_md5}"
      end
      feeds_with_page
    else
      page
    end
    if feeds_with_page == nil do
      handle_404(conn)
    else
      if cursor == nil do
        render(conn, "tag.html", posts: feeds_with_page.edge_hashtag_to_media.posts, page_info: feeds_with_page.edge_hashtag_to_media.page_info, tag: feeds_with_page, seo: SEO.get_tag_seo(feeds_with_page))
      else
        conn
        |> put_layout(false)
        |> put_view(InstaghubWeb.HtmlView)
        |> render("posts.html", posts: feeds_with_page.edge_hashtag_to_media.posts, page_info: feeds_with_page.edge_hashtag_to_media.page_info)
      end
    end
  end

  def search(conn, %{"item" => item} = _params) do
    cursor = Cache.get_cursor(conn)
    redis_key_md5 = Cache.get_page_key(conn, cursor)
    page = Cache.get_page(conn)
    feeds_with_page =
    if page == nil do
      feeds_with_page = API.search_tags_users(item)
      if feeds_with_page != nil do
        feeds_bin = :erlang.term_to_binary(feeds_with_page)
        RedisUtil.setx(redis_key_md5, feeds_bin)
        Logger.debug "get page with api and store in redis with key #{redis_key_md5}"
      end
      feeds_with_page
    else
      page
    end
    if feeds_with_page == nil do
      handle_404(conn)
    else
      tags = feeds_with_page.hashtags
      users = feeds_with_page.users
      render(conn, "search.html", items: tags ++ users |> Enum.shuffle)
    end
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html", [])
  end

  def about(conn, _params) do
    render(conn, "about.html", [])
  end
end
