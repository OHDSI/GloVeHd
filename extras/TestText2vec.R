library(text2vec)
text8Folder <- "d:/temp"
if (!file.exists(file.path(text8Folder, "text8"))) {
  tempFile <- tempfile(fileext = ".zip")
  download.file("http://mattmahoney.net/dc/text8.zip", tempFile)
  unzip (tempFile, files = "text8", exdir = text8Folder)
  unlink(tempFile)
}
wiki = readLines(file.path(text8Folder, "text8"), n = 1, warn = FALSE)

# Create iterator over tokens
tokens = space_tokenizer(wiki)

# Create vocabulary. Terms will be unigrams (simple words).
it = itoken(tokens, progressbar = FALSE)
vocab = create_vocabulary(it)

vocab = prune_vocabulary(vocab, term_count_min = 5L)

# Use our filtered vocabulary
vectorizer = vocab_vectorizer(vocab)
# use window of 5 for context words
tcm = create_tcm(it, vectorizer, skip_grams_window = 5L)

glove = GlobalVectors$new(rank = 50, x_max = 10)
wv_main = glove$fit_transform(tcm, n_iter = 10, convergence_tol = 0.01, n_threads = 8)

dim(wv_main)

wv_context = glove$components
dim(wv_context)

word_vectors = wv_main + t(wv_context)

berlin = word_vectors["paris", , drop = FALSE] - 
  word_vectors["france", , drop = FALSE] + 
  word_vectors["germany", , drop = FALSE]
cos_sim = sim2(x = word_vectors, y = berlin, method = "cosine", norm = "l2")
head(sort(cos_sim[,1], decreasing = TRUE), 5)