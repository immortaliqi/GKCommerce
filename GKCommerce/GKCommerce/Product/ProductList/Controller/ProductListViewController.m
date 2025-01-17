//
//  ProductListViewController.m
//  goku-commerce.com
//
//  Created by 小悟空 on 14-9-3.
//  Copyright (c) 2014年 小悟空. All rights reserved.
//

#import "ProductListViewController.h"
#import "ProductDetailViewController.h"
#import "ProductListCollectionViewCell.h"
#import "SVPullToRefresh.h"

@interface ProductListViewController ()

@end

@implementation ProductListViewController

- (id)initWithProductCategory:(ProductCategory *)category user:(GKUser *)anUser
{
    SearchBackendModel *search = [[SearchBackendModel alloc] init];
    search.productCategoryID = category.categoryID;
    self = [self initWithSearchModel:search user:anUser];
    if (self) {
        self.productCategory = category;
    }
    return self;
}

- (id)initWithSearchModel:(SearchBackendModel *)searchModel user:(GKUser *)anUser
{
    self = [self initWithNibName:@"ProductListView" bundle:nil];
    if (self) {
        self.search = searchModel;
        self.user = anUser;
        self.products = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.productCategory)
        self.title = self.productCategory.name;
    else
        self.navigationItem.title = @"选购";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    for (NSString *identifier in @[@"ProductListCollectionViewCell"])
        [self.collectionView registerNib:[UINib nibWithNibName:identifier
                                                        bundle:nil]
              forCellWithReuseIdentifier:identifier];

    [self.collectionView addPullToRefreshWithActionHandler:^{
        self.search.page = 1;
      
      [[self.service productsWithSearchModel:self.search]
       subscribeNext:[self didLoadProductsWithSearchModel]];

        CGPoint point = self.collectionView.contentOffset;
        point.y = 0;
        self.collectionView.contentOffset = point;
    }];
    
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        self.search.page += 1;
        [self.service productsWithSearchModel:self.search];
    }];
    self.collectionView.showsInfiniteScrolling = NO;
    
    [[self.service productsWithSearchModel:self.search]
     subscribeNext:[self didLoadProductsWithSearchModel]];
    
    [self.segmentView reloadData];
}

- (void(^)(RACTuple *))didLoadProductsWithSearchModel
{
  @weakify(self)
  return ^(RACTuple *parameters) {
    @strongify(self)
    
    RACTupleUnpack(SearchBackendModel *searchModel,
                   NSArray *products) = parameters;
    BOOL more;
    more = searchModel.page > 1;
    
    if (more) {
      [self.collectionView.infiniteScrollingView stopAnimating];
      [self.products addObjectsFromArray:products];
    } else {
      [self.collectionView.pullToRefreshView stopAnimating];
      self.products = [NSMutableArray arrayWithArray:products];
    }
    
    [self.collectionView reloadData];
    self.collectionView.showsInfiniteScrolling = [searchModel hasMore];
  };
}

- (void)segmentView:(GKSegmentView *)segmentView
   didSelectAtIndex:(NSInteger)index
{
    switch (index) {
        case 1:
            self.search.sort = @"price_asc";
            break;
        case 2:
            self.search.sort = @"price_desc";
            break;
        case 0:
        default:
            self.search.sort = @"id_desc";
            break;
    }
    [[self.service productsWithSearchModel:self.search]
     subscribeNext:[self didLoadProductsWithSearchModel]];
}

- (NSInteger)numberOfSegments
{
    return 3;
}

- (NSString *)segmentView:(GKSegmentView *)segmentView
titleForSegmentAtIndex:(NSInteger)index
{
    NSString *title;
    switch (index) {
        case 0:
            title = @"新品";
            break;
        case 1:
            title = @"价格最低";
            break;
        case 2:
            title = @"价格最高";
            break;
        default:
            break;
    }
    return title;
}

#pragma mark- UICollectionView
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    NSInteger numbers = self.products.count;
    return numbers;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ProductListCollectionViewCell *cell;
    Product *product;
    
    cell = [collectionView
            dequeueReusableCellWithReuseIdentifier:@"ProductListCollectionViewCell"
            forIndexPath:indexPath];
    product = [self.products objectAtIndex:indexPath.row];
    cell.product = product;

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Product *product = [self.products objectAtIndex:indexPath.row];
    
    ProductDetailViewController *viewController;
    viewController = [[ProductDetailViewController alloc]
                      initWithProductID:product.productID
                      user:self.user];
    viewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark --UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(148, 194);
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                       layout:(UICollectionViewLayout *)collectionViewLayout
       insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 7, 5, 7);
}
@end
