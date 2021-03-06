#' Baixar processos de segunda instância do tjsp
#'
#' @param processos processos de segunda instância
#' @param diretorio diretório
#'
#' @return html com dados processuais
#' @export
#'
baixar_cposg <- function(processos = NULL,
                         diretorio = ".") {

  httr::set_config(httr::config(ssl_verifypeer = FALSE))

  processos <- stringr::str_remove_all(processos, "\\D+") %>%
    stringr::str_pad(width = 20, "left", "0") %>%
    abjutils::build_id()

  uri1 <- "https://esaj.tjsp.jus.br/cposg/search.do?"

  purrr::walk(processos, purrr::possibly(purrrogress::with_progress(~{

  r<-  httr::GET("https://esaj.tjsp.jus.br/cposg/open.do?gateway=true")

     p <- .x

    unificado <- p %>%
      stringr::str_extract(".{15}")

    foro <- p %>%
      stringr::str_extract("\\d{4}$")

  query1<-  list(conversationId = "", paginaConsulta = "1", localPesquisa.cdLocal = "-1",
         cbPesquisa = "NUMPROC", tipoNuProcesso = "UNIFICADO", numeroDigitoAnoUnificado = unificado,
         foroNumeroUnificado = foro, dePesquisaNuUnificado = p,
         dePesquisa = "", uuidCaptcha = "", pbEnviar = "Pesquisar")

    resposta1 <- httr::RETRY("GET",
      url = uri1, query = query1,
      quiet = TRUE, httr::timeout(2)
    )

    conteudo1 <- httr::content(resposta1)

    if (xml2::xml_find_first(conteudo1, "boolean(//div[@id='listagemDeProcessos'])")) {
      conteudo1 <- xml2::xml_find_all(conteudo1, "//a[@class='linkProcesso']") %>%
        xml2::xml_attr("href") %>%
        xml2::url_absolute("https://esaj.tjsp.jus.br") %>%
        purrr::map(~ httr::RETRY("GET", .x, httr::timeout(2)) %>%
          httr::content())
    } else {
      conteudo1 <- list(conteudo1)
    }

    p <- stringr::str_remove_all(p, "\\D+")
    arquivo <- file.path(diretorio, paste0(format(Sys.Date(), "%Y_%m_%d_"), p, ".html"))

    xml2::write_html(conteudo1[[1]], arquivo)
  }), NULL))
}
