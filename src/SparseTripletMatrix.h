// Borrowed from https://raw.githubusercontent.com/dselivanov/text2vec/master/src/SparseTripletMatrix.h

#include <Rcpp.h>
#include <string>
#include <vector>
#include <memory>

#define SPP_MIX_HASH

// #include "text2vec.h"

using namespace std;
using namespace Rcpp;


namespace std {
template <>
struct hash<std::pair<uint32_t, uint32_t>>
{
  inline uint64_t operator()(const std::pair<uint32_t, uint32_t>& k) const
  {
    return (uint64_t) k.first << 32 | k.second;
  }
};

}

template<typename T>
class SparseTripletMatrix {
public:
  // constructor for sparse matrix
  SparseTripletMatrix():
  nrow(0), ncol(0), nnz(0) {};
  
  SparseTripletMatrix(uint32_t nrow, uint32_t ncol):
    nrow(nrow), ncol(ncol), nnz(0) {};
  
  inline void increment_nrows() {this->nrow++;};
  inline void increment_ncols() {this->ncol++;};
  
  inline uint32_t nrows() {return this->nrow;};
  inline uint32_t ncols() {return this->ncol;};
  inline size_t size() {
    return(this->sparse_container.size());
  }
  void clear() { this->sparse_container.clear(); };
  // add or increment elements
  void add(uint32_t i, uint32_t j, T increment) {
    // simply add our increment
    this->sparse_container[make_pair(i, j)] += increment;
  };
  
  S4 get_sparse_triplet_matrix(CharacterVector  &rownames, CharacterVector  &colnames);
private:
  // dimensionality of matrix
  uint32_t nrow;
  uint32_t ncol;
  // number of non-zero elements in matrix
  size_t nnz;
  // container for sparse matrix in triplet form
  std::unordered_map< pair<uint32_t, uint32_t>, T> sparse_container;

};

template<typename T>
S4 SparseTripletMatrix<T>::get_sparse_triplet_matrix(CharacterVector  &rownames, CharacterVector  &colnames) {
  // non-zero values count
  size_t NNZ = this->size();
  
  // result triplet sparse matrix
  S4 triplet_matrix("dgTMatrix");
  
  // index vectors
  IntegerVector I(NNZ), J(NNZ);
  // value vector
  NumericVector X(NNZ);
  
  size_t n = 0;
  for(auto it : sparse_container) {
    // fill first half of our symmetric cooccurence matrix
    I[n] = it.first.first;
    J[n] = it.first.second;
    X[n] = it.second;
    n++;
  }
  // construct matrix
  triplet_matrix.slot("i") = I;
  triplet_matrix.slot("j") = J;
  triplet_matrix.slot("x") = X;
  // set dimensions
  triplet_matrix.slot("Dim") =
    IntegerVector::create(max(nrow, (uint32_t)rownames.size()),
                          max(ncol, (uint32_t)colnames.size()));
  // set dimension names
  triplet_matrix.slot("Dimnames") = List::create(rownames, colnames);
  return triplet_matrix;
}