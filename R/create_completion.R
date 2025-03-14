#' Create completion
#'
#' Creates a completion based on the provided prompt and parameters. See [this
#' page](https://platform.openai.com/docs/api-reference/completions/create) for
#' details.
#'
#' For arguments description please refer to the [official
#' documentation](https://platform.openai.com/docs/api-reference/completions/create).
#'
#' @param engine_id `r lifecycle::badge("deprecated")`
#' @param model required; a length one character vector.
#' @param prompt required; defaults to `"<|endoftext|>"`; an arbitrary length
#'   character vector.
#' @param suffix optional; defaults to `NULL`; a length one character vector.
#' @param max_tokens required; defaults to `16`; a length one numeric vector
#'   with the integer value greater than `0`.
#' @param temperature required; defaults to `1`; a length one numeric vector
#'   with the value between `0` and `2`.
#' @param top_p required; defaults to `1`; a length one numeric vector with the
#'   value between `0` and `1`.
#' @param n required; defaults to `1`; a length one numeric vector with the
#'   integer value greater than `0`.
#' @param stream required; defaults to `FALSE`; a length one logical vector.
#'   **Currently is not implemented.**
#' @param logprobs optional; defaults to `NULL`; a length one numeric vector
#'   with the integer value between `0` and `5`.
#' @param echo required; defaults to `FALSE`; a length one logical vector.
#' @param stop optional; defaults to `NULL`; a character vector of length
#'   between one and four.
#' @param presence_penalty required; defaults to `0`; a length one numeric
#'   vector with a value between `-2` and `2`.
#' @param frequency_penalty required; defaults to `0`; a length one numeric
#'   vector with a value between `-2` and `2`.
#' @param best_of required; defaults to `1`; a length one numeric vector with
#'   the integer value greater than `0`.
#' @param logit_bias optional; defaults to `NULL`; a named list.
#' @param user optional; defaults to `NULL`; a length one character vector.
#' @param openai_api_key required; defaults to `Sys.getenv("OPENAI_API_KEY")`
#'   (i.e., the value is retrieved from the `.Renviron` file); a length one
#'   character vector. Specifies OpenAI API key.
#' @param openai_organization optional; defaults to `NULL`; a length one
#'   character vector. Specifies OpenAI organization.
#' @return Returns a list, elements of which contain completion(s) and
#'   supplementary information.
#' @examples \dontrun{
#' create_completion(
#'     model = "text-davinci-002",
#'     prompt = "Say this is a test",
#'     max_tokens = 5
#' )
#'
#' logit_bias <- list(
#'     "11" = -100,
#'     "13" = -100
#' )
#' create_completion(
#'     model = "ada",
#'     prompt = "Generate a question and an answer",
#'     n = 4,
#'     best_of = 4,
#'     logit_bias = logit_bias
#' )
#' }
#' @export
create_completion <- function(
        engine_id = deprecated(),
        model,
        prompt = "<|endoftext|>",
        suffix = NULL,
        max_tokens = 16,
        temperature = 1,
        top_p = 1,
        n = 1,
        stream = FALSE,
        logprobs = NULL,
        echo = FALSE,
        stop = NULL,
        presence_penalty = 0,
        frequency_penalty = 0,
        best_of = 1,
        logit_bias = NULL,
        user = NULL,
        openai_api_key = Sys.getenv("OPENAI_API_KEY"),
        openai_organization = NULL
) {

    if (lifecycle::is_present(engine_id)) {
        lifecycle::deprecate_warn(
            "0.3.0",
            "create_completion(engine_id)",
            "create_completion(model)"
        )
        model <- engine_id
    }

    #---------------------------------------------------------------------------
    # Validate arguments

    assertthat::assert_that(
        assertthat::is.string(model),
        assertthat::noNA(model)
    )

    assertthat::assert_that(
        is.character(prompt),
        assertthat::noNA(prompt)
    )

    if (!is.null(suffix)) {
        assertthat::assert_that(
            assertthat::is.string(suffix),
            assertthat::noNA(suffix)
        )
    }

    assertthat::assert_that(
        assertthat::is.count(max_tokens)
    )

    assertthat::assert_that(
        assertthat::is.number(temperature),
        assertthat::noNA(temperature),
        value_between(temperature, 0, 2)
    )

    assertthat::assert_that(
        assertthat::is.number(top_p),
        assertthat::noNA(top_p),
        value_between(top_p, 0, 1)
    )

    if (both_specified(temperature, top_p)) {
        warning(
            "It is recommended NOT to specify temperature and top_p at a time."
        )
    }

    assertthat::assert_that(
        assertthat::is.count(n)
    )

    assertthat::assert_that(
        assertthat::is.flag(stream),
        assertthat::noNA(stream),
        is_false(stream)
    )

    if (!is.null(logprobs)) {
        assertthat::assert_that(
            assertthat::is.count(logprobs + 1),
            value_between(logprobs, 0, 5)

        )
    }

    assertthat::assert_that(
        assertthat::is.flag(echo),
        assertthat::noNA(echo)
    )

    if (!is.null(stop)) {
        assertthat::assert_that(
            is.character(stop),
            assertthat::noNA(stop),
            length_between(stop, 1, 4)
        )
    }

    assertthat::assert_that(
        assertthat::is.number(presence_penalty),
        assertthat::noNA(presence_penalty),
        value_between(presence_penalty, -2, 2)
    )

    assertthat::assert_that(
        assertthat::is.number(frequency_penalty),
        assertthat::noNA(frequency_penalty),
        value_between(frequency_penalty, -2, 2)
    )

    assertthat::assert_that(
        assertthat::is.count(best_of)
    )

    assertthat::assert_that(
        best_of >= n
    )

    if (!is.null(logit_bias)) {
        assertthat::assert_that(
            is.list(logit_bias)
        )
    }

    if (!is.null(user)) {
        assertthat::assert_that(
            assertthat::is.string(user),
            assertthat::noNA(user)
        )
    }

    assertthat::assert_that(
        assertthat::is.string(openai_api_key),
        assertthat::noNA(openai_api_key)
    )

    if (!is.null(openai_organization)) {
        assertthat::assert_that(
            assertthat::is.string(openai_organization),
            assertthat::noNA(openai_organization)
        )
    }

    #---------------------------------------------------------------------------
    # Build path parameters

    task <- "completions"

    base_url <- Sys.getenv("https://gpt-api.freeoai.com/v1")
        print(base_url)

    base_url <- glue::glue("{base_url}/{task}")

    headers <- c(
        "Authorization" = paste("Bearer", openai_api_key),
        "Content-Type" = "application/json"
    )

    if (!is.null(openai_organization)) {
        headers["OpenAI-Organization"] <- openai_organization
    }

    #---------------------------------------------------------------------------
    # Build request body

    body <- list()
    body[["model"]] <- model
    body[["prompt"]] <- prompt
    body[["suffix"]] <- suffix
    body[["max_tokens"]] <- max_tokens
    body[["temperature"]] <- temperature
    body[["top_p"]] <- top_p
    body[["n"]] <- n
    body[["stream"]] <- stream
    body[["logprobs"]] <- logprobs
    body[["echo"]] <- echo
    body[["stop"]] <- stop
    body[["presence_penalty"]] <- presence_penalty
    body[["frequency_penalty"]] <- frequency_penalty
    body[["best_of"]] <- best_of
    body[["logit_bias"]] <- logit_bias
    body[["user"]] <- user

    #---------------------------------------------------------------------------
    # Make a request and parse it

    response <- httr::POST(
        url = base_url,
        httr::add_headers(.headers = headers),
        body = body,
        encode = "json"
    )

    verify_mime_type(response)

    parsed <- response %>%
        httr::content(as = "text", encoding = "UTF-8") %>%
        jsonlite::fromJSON(flatten = TRUE)

    #---------------------------------------------------------------------------
    # Check whether request failed and return parsed

    if (httr::http_error(response)) {
        paste0(
            "OpenAI API request failed [",
            httr::status_code(response),
            "]:\n\n",
            parsed$error$message
        ) %>%
            stop(call. = FALSE)
    }

    parsed

}
