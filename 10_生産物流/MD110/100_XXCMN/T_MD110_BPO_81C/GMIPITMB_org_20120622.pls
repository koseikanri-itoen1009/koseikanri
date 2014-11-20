create or replace PACKAGE BODY GMI_ITEM_PUB AS
--$Header: GMIPITMB.pls 115.13.115100.2 2005/12/21 16:26:58 adeshmuk ship $
-- Body start of comments
--+==========================================================================+
--|                   Copyright (c) 1998 Oracle Corporation                  |
--|                          Redwood Shores, CA, USA                         |
--|                            All rights reserved.                          |
--+==========================================================================+
--| FILE NAME                                                                |
--|    GMIPITMB.pls                                                          |
--|                                                                          |
--| PACKAGE NAME                                                             |
--|    GMI_ITEM_PUB                                                          |
--|                                                                          |
--| DESCRIPTION                                                              |
--|    This package conatains all APIs related to the Business Object Item   |
--|                                                                          |
--| CONTENTS                                                                 |
--|    Create_Item                                                           |
--|    Validate_Item                                                         |
--|                                                                          |
--| HISTORY                                                                  |
--|    15-FEB-1999  M.Godfrey     Upgraded to R11.                           |
--|    16-AUG-1999  Liz Enstone   B965832(1) Several changes to fix          |
--|                                  problems with status_ctl                |
--|    20/AUG/1999  H.Verdding Bug 951828 Change GMS package Calls to GMA    |
--|    02/Mar/2000  Liz Enstone Bug 1222126 qc_grade,lot_status not being    |
--|                 written to ic_item_mst
--|    13/Mar/2000  Liz Enstone Bug 1231196 Don't write records to ic_item_  |
--|                 cpg as CPG is not supported from 11.5                    |
--|                 Fix has also got rid of superfluous debugging messages   |
--|    23/Oct/2001  Joe DiIorio Bug 1989860 11.5.1H - Removed references to  |
--|                 Intrastat and commodity code. i.e. SY$INTRASTAT.         |
--|    28/Oct/2002  Joe DiIorio Bug 2643440 11.5.1J - Added nocopy.          |
--+==========================================================================+
-- Body end of comments
-- Global variables
G_PKG_NAME      CONSTANT VARCHAR2(30):='GMI_ITEM_PUB';
IC$DEFAULT_LOT           VARCHAR2(255);
-- Api start of comments
--+==========================================================================+
--| PROCEDURE NAME                                                           |
--|    Create_Item                                                           |
--|                                                                          |
--| TYPE                                                                     |
--|    Public                                                                |
--|                                                                          |
--| USAGE                                                                    |
--|    Create a new Item in Item Master                                      |
--|                                                                          |
--| DESCRIPTION                                                              |
--|    This procedure creates a new inventory item                           |
--|                                                                          |
--| PARAMETERS                                                               |
--|    p_api_version      IN  NUMBER       - Api Version                     |
--|    p_init_msg_list    IN  VARCHAR2     - Message Initialization Ind.     |
--|    p_commit           IN  VARCHAR2     - Commit Indicator                |
--|    p_validation_level IN  VARCHAR2     - Validation Level Indicator      |
--|    p_item_rec         IN  item_rec_typ - Item Master details             |
--|    x_return_status    OUT VARCHAR2     - Return Status                   |
--|    x_msg_count        OUT NUMBER       - Number of messages              |
--|    x_msg_data         OUT VARCHAR2     - Messages in encoded format      |
--|                                                                          |
--| RETURNS                                                                  |
--|    None                                                                  |
--|                                                                          |
--| HISTORY                                                                  |
--|                                                                          |
--|    Archana Mundhe 19-Dec-2005 Bug 4895755                                |
--|    Modified check for user_id as 0 is a valid user id for user sysadmin. |
--+==========================================================================+
-- Api end of comments
PROCEDURE Create_item
( p_api_version      IN NUMBER
, p_init_msg_list    IN VARCHAR2 :=FND_API.G_FALSE
, p_commit           IN VARCHAR2 :=FND_API.G_FALSE
, p_validation_level IN VARCHAR2 :=FND_API.G_VALID_LEVEL_FULL
, p_item_rec         IN item_rec_typ
, x_return_status    OUT NOCOPY VARCHAR2
, x_msg_count        OUT NOCOPY NUMBER
, x_msg_data         OUT NOCOPY VARCHAR2
)
IS
l_api_name    CONSTANT VARCHAR2 (30) :='Create_Item';
l_api_version CONSTANT NUMBER        :=2.0;
l_msg_count            NUMBER;
l_msg_data             VARCHAR2(2000);
l_return_status        VARCHAR2(1);
l_qcitem_no            VARCHAR2(32);
l_whse_item_no         VARCHAR2(32);
l_item_id              ic_item_mst.item_id%TYPE  :=0;
l_item_no              ic_item_mst.item_no%TYPE;
l_item_desc1           ic_item_mst.item_desc1%TYPE;
l_item_um              ic_item_mst.item_um%TYPE;
l_item_um2             ic_item_mst.item_um2%TYPE;
l_qcitem_id            ic_item_mst.qcitem_id%TYPE;
l_whse_item_id         ic_item_mst.whse_item_id%TYPE;
l_user_name            fnd_user.user_name%TYPE;
l_user_id              fnd_user.user_id%TYPE;
l_ic_item_mst_rec      ic_item_mst%ROWTYPE;
l_ic_item_cpg_rec      ic_item_cpg%ROWTYPE;
l_lot_rec              GMI_LOTS_PUB.lot_rec_typ;
--B965832(1) Add the following variables
l_lot_status           ic_item_mst.lot_status%TYPE;
l_qc_grade             ic_item_mst.qc_grade%TYPE;

BEGIN

-- Standard Start OF API savepoint
  SAVEPOINT Create_Item;
-- Standard call to check for call compatibility.
  IF NOT FND_API.Compatible_API_CALL (  l_api_version
                                      , p_api_version
                                      , l_api_name
                                      , G_PKG_NAME
                                     )
  THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;
-- Initialize message list if p_int_msg_list is set TRUE.
  IF FND_API.to_boolean(p_init_msg_list)
  THEN
    FND_MSG_PUB.Initialize;
  END IF;
-- Initialize API return status to sucess
  x_return_status := FND_API.G_RET_STS_SUCCESS;

-- Populate WHO columns
  GMA_GLOBAL_GRP.Get_who( p_user_name  => p_item_rec.user_name
                        , x_user_id    => l_user_id
                        );


  -- Bug 4895755
  -- Modified check for user_id as 0 is a valid
  -- user id for user sysadmin.
  IF l_user_id = -1
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_USER_NAME');
    FND_MESSAGE.SET_TOKEN('USER_NAME',p_item_rec.user_name);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Get required system constants
  IC$DEFAULT_LOT  := FND_PROFILE.Value_Specific( name    => 'IC$DEFAULT_LOT'
                                               , user_id => l_user_id
                                               );
  IF (IC$DEFAULT_LOT IS NULL)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_UNABLE_TO_GET_CONSTANT');
    FND_MESSAGE.SET_TOKEN('CONSTANT_NAME','IC$DEFAULT_LOT');
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;


  l_qcitem_no    := UPPER(p_item_rec.qcitem_no);
  l_whse_item_no := UPPER(p_item_rec.whse_item_no);
  l_user_name    := UPPER(p_item_rec.user_name);

-- Ensure Upper-case columns are converted

  l_item_no  := UPPER(p_item_rec.item_no);
  l_item_um  := p_item_rec.item_um;
  l_item_um2 := p_item_rec.item_um2;


-- Perform Validation
   GMI_ITEM_PUB.Validate_Item (  p_api_version    => 2.0
                               , p_init_msg_list  => FND_API.G_FALSE
                               , p_item_rec       =>p_item_rec
                               , x_return_status  =>l_return_status
                               , x_msg_count      =>l_msg_count
                               , x_msg_data       =>l_msg_data
                              );

-- If errors were found then raise exception
  IF (l_return_status = FND_API.G_RET_STS_ERROR)
  THEN
    RAISE FND_API.G_EXC_ERROR;
  END IF;
-- If no errors were found then proceed with the item create

-- First get the surrogate key (item_id) for the item
  SELECT gem5_item_id_s.nextval INTO l_item_id FROM dual;
  IF (l_item_id <=0)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_UNABLE_TO_GET_SURROGATE');
    FND_MESSAGE.SET_TOKEN('SKEY','item_id');
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Get item_id of warehouse item and QC reference item if required
  l_qcitem_id    := GMI_VALID_GRP.Validate_item_existance(l_qcitem_no);
  IF (l_qcitem_id = 0)
  THEN
    l_qcitem_id := NULL;
  END IF;

  l_whse_item_id := GMI_VALID_GRP.Validate_item_existance(l_whse_item_no);

  IF (l_whse_item_id = 0)
  THEN
    l_whse_item_id := l_item_id;
  END IF;

-- Set up PL/SQL record and insert item into ic_item_mst

l_ic_item_mst_rec.item_id            := l_item_id;
l_ic_item_mst_rec.item_no            := l_item_no;
l_ic_item_mst_rec.item_desc1         := p_item_rec.item_desc1;
l_ic_item_mst_rec.item_desc2         := p_item_rec.item_desc2;
l_ic_item_mst_rec.alt_itema          := UPPER(p_item_rec.alt_itema);
l_ic_item_mst_rec.alt_itemb          := UPPER(p_item_rec.alt_itemb);
l_ic_item_mst_rec.item_um            := l_item_um;
l_ic_item_mst_rec.dualum_ind         := p_item_rec.dualum_ind;
l_ic_item_mst_rec.item_um2           := l_item_um2;
l_ic_item_mst_rec.deviation_lo       := p_item_rec.deviation_lo;
l_ic_item_mst_rec.deviation_hi       := p_item_rec.deviation_hi;
l_ic_item_mst_rec.level_code         := p_item_rec.level_code;
l_ic_item_mst_rec.lot_ctl            := p_item_rec.lot_ctl;
l_ic_item_mst_rec.lot_indivisible    := p_item_rec.lot_indivisible;
l_ic_item_mst_rec.sublot_ctl         := p_item_rec.sublot_ctl;
l_ic_item_mst_rec.loct_ctl           := p_item_rec.loct_ctl;
l_ic_item_mst_rec.noninv_ind         := p_item_rec.noninv_ind;
l_ic_item_mst_rec.match_type         := p_item_rec.match_type;
l_ic_item_mst_rec.inactive_ind       := p_item_rec.inactive_ind;
l_ic_item_mst_rec.inv_type           := p_item_rec.inv_type;
l_ic_item_mst_rec.shelf_life         := p_item_rec.shelf_life;
l_ic_item_mst_rec.retest_interval    := p_item_rec.retest_interval;
l_ic_item_mst_rec.item_abccode       := UPPER(p_item_rec.item_abccode);
l_ic_item_mst_rec.gl_class           := UPPER(p_item_rec.gl_class);
l_ic_item_mst_rec.inv_class          := UPPER(p_item_rec.inv_class);
l_ic_item_mst_rec.sales_class        := UPPER(p_item_rec.sales_class);
l_ic_item_mst_rec.ship_class         := UPPER(p_item_rec.ship_class);
l_ic_item_mst_rec.frt_class          := UPPER(p_item_rec.frt_class);
l_ic_item_mst_rec.price_class        := UPPER(p_item_rec.price_class);
l_ic_item_mst_rec.storage_class      := UPPER(p_item_rec.storage_class);
l_ic_item_mst_rec.purch_class        := UPPER(p_item_rec.purch_class);
l_ic_item_mst_rec.tax_class          := UPPER(p_item_rec.tax_class);
l_ic_item_mst_rec.customs_class      := UPPER(p_item_rec.customs_class);
l_ic_item_mst_rec.alloc_class        := UPPER(p_item_rec.alloc_class);
l_ic_item_mst_rec.planning_class     := UPPER(p_item_rec.planning_class);
l_ic_item_mst_rec.itemcost_class     := UPPER(p_item_rec.itemcost_class);
l_ic_item_mst_rec.cost_mthd_code     := UPPER(p_item_rec.cost_mthd_code);
l_ic_item_mst_rec.upc_code           := p_item_rec.upc_code;
l_ic_item_mst_rec.grade_ctl          := p_item_rec.grade_ctl;
l_ic_item_mst_rec.status_ctl         := p_item_rec.status_ctl;
--B965832(1) Comment these 2 variables out here
--B1222126 Restore these 2 lines.  qc_grade and lot_status are not being
--saved
l_ic_item_mst_rec.qc_grade           := UPPER(p_item_rec.qc_grade);
l_ic_item_mst_rec.lot_status         := UPPER(p_item_rec.lot_status);
l_ic_item_mst_rec.bulk_id            := p_item_rec.bulk_id;
l_ic_item_mst_rec.pkg_id             := p_item_rec.pkg_id;
l_ic_item_mst_rec.qcitem_id          := l_qcitem_id;
l_ic_item_mst_rec.qchold_res_code    := UPPER(p_item_rec.qchold_res_code);
l_ic_item_mst_rec.expaction_code     := UPPER(p_item_rec.expaction_code);
l_ic_item_mst_rec.fill_qty           := p_item_rec.fill_qty;
l_ic_item_mst_rec.fill_um            := p_item_rec.fill_um;
l_ic_item_mst_rec.expaction_interval := p_item_rec.expaction_interval;
l_ic_item_mst_rec.phantom_type       := p_item_rec.phantom_type;
l_ic_item_mst_rec.whse_item_id       := l_whse_item_id;
l_ic_item_mst_rec.experimental_ind   := p_item_rec.experimental_ind;
l_ic_item_mst_rec.exported_date      := GMA_GLOBAL_GRP.SY$MIN_DATE;
l_ic_item_mst_rec.creation_date      := SYSDATE;
l_ic_item_mst_rec.last_update_date   := SYSDATE;
l_ic_item_mst_rec.created_by         := l_user_id;
l_ic_item_mst_rec.last_updated_by    := l_user_id;
l_ic_item_mst_rec.last_update_login  := TO_NUMBER(FND_PROFILE.Value(
                                        'LOGIN_ID'));
l_ic_item_mst_rec.trans_cnt          := 1;
l_ic_item_mst_rec.delete_mark        := 0;
l_ic_item_mst_rec.text_code          := NULL;
l_ic_item_mst_rec.seq_dpnd_class     := UPPER(p_item_rec.seq_dpnd_class);
l_ic_item_mst_rec.commodity_code     := p_item_rec.commodity_code;
l_ic_item_mst_rec.attribute1         := UPPER(p_item_rec.attribute1);
l_ic_item_mst_rec.attribute2         := UPPER(p_item_rec.attribute2);
l_ic_item_mst_rec.attribute3         := UPPER(p_item_rec.attribute3);
l_ic_item_mst_rec.attribute4         := UPPER(p_item_rec.attribute4);
l_ic_item_mst_rec.attribute5         := UPPER(p_item_rec.attribute5);
l_ic_item_mst_rec.attribute6         := UPPER(p_item_rec.attribute6);
l_ic_item_mst_rec.attribute7         := UPPER(p_item_rec.attribute7);
l_ic_item_mst_rec.attribute8         := UPPER(p_item_rec.attribute8);
l_ic_item_mst_rec.attribute9         := UPPER(p_item_rec.attribute9);
l_ic_item_mst_rec.attribute10        := UPPER(p_item_rec.attribute10);
l_ic_item_mst_rec.attribute11        := UPPER(p_item_rec.attribute11);
l_ic_item_mst_rec.attribute12        := UPPER(p_item_rec.attribute12);
l_ic_item_mst_rec.attribute13        := UPPER(p_item_rec.attribute13);
l_ic_item_mst_rec.attribute14        := UPPER(p_item_rec.attribute14);
l_ic_item_mst_rec.attribute15        := UPPER(p_item_rec.attribute15);
l_ic_item_mst_rec.attribute16        := UPPER(p_item_rec.attribute16);
l_ic_item_mst_rec.attribute17        := UPPER(p_item_rec.attribute17);
l_ic_item_mst_rec.attribute18        := UPPER(p_item_rec.attribute18);
l_ic_item_mst_rec.attribute19        := UPPER(p_item_rec.attribute19);
l_ic_item_mst_rec.attribute20        := UPPER(p_item_rec.attribute20);
l_ic_item_mst_rec.attribute21        := UPPER(p_item_rec.attribute21);
l_ic_item_mst_rec.attribute22        := UPPER(p_item_rec.attribute22);
l_ic_item_mst_rec.attribute23        := UPPER(p_item_rec.attribute23);
l_ic_item_mst_rec.attribute24        := UPPER(p_item_rec.attribute24);
l_ic_item_mst_rec.attribute25        := UPPER(p_item_rec.attribute25);
l_ic_item_mst_rec.attribute26        := UPPER(p_item_rec.attribute26);
l_ic_item_mst_rec.attribute27        := UPPER(p_item_rec.attribute27);
l_ic_item_mst_rec.attribute28        := UPPER(p_item_rec.attribute28);
l_ic_item_mst_rec.attribute29        := UPPER(p_item_rec.attribute29);
l_ic_item_mst_rec.attribute30        := UPPER(p_item_rec.attribute30);
l_ic_item_mst_rec.attribute_category := UPPER(p_item_rec.attribute_category);

-- dbms_output.put_line('item_id   '||'!'||l_item_id||'!');
-- dbms_output.put_line('item_no   '||'!'||l_item_no||'!');
-- dbms_output.put_line('item_desc1  '||'!'||p_item_rec.item_desc1||'!');
-- dbms_output.put_line('item_desc2  '||'!'||p_item_rec.item_desc2||'!');
-- dbms_output.put_line('alt_itema   '||'!'||UPPER(p_item_rec.alt_itema)||'!');
-- dbms_output.put_line('alt_itemb   '||'!'||UPPER(p_item_rec.alt_itemb)||'!');
-- dbms_output.put_line('item_um   '||'!'||l_item_um||'!');
-- dbms_output.put_line('dualum_ind  '||'!'||p_item_rec.dualum_ind||'!');
-- dbms_output.put_line('item_um2   '||'!'||l_item_um2||'!');
-- dbms_output.put_line('deviation_lo  '||'!'||p_item_rec.deviation_lo||'!');
-- dbms_output.put_line('deviation_hi  '||'!'||p_item_rec.deviation_hi||'!');
-- dbms_output.put_line('level_code  '||'!'||p_item_rec.level_code||'!');
-- dbms_output.put_line('lot_ctl   '||'!'||p_item_rec.lot_ctl||'!');
-- dbms_output.put_line('lot_indivisible  '||'!'||p_item_rec.lot_indivisible||'!');
-- dbms_output.put_line('sublot_ctl  '||'!'||p_item_rec.sublot_ctl||'!');
-- dbms_output.put_line('loct_ctl   '||'!'||p_item_rec.loct_ctl||'!');
-- dbms_output.put_line('noninv_ind  '||'!'||p_item_rec.noninv_ind||'!');
-- dbms_output.put_line('match_type  '||'!'||p_item_rec.match_type||'!');
-- dbms_output.put_line('inactive_ind  '||'!'||p_item_rec.inactive_ind||'!');
-- dbms_output.put_line('inv_type   '||'!'||p_item_rec.inv_type||'!');
-- dbms_output.put_line('shelf_life  '||'!'||p_item_rec.shelf_life||'!');
-- dbms_output.put_line('retest_interval  '||'!'||p_item_rec.retest_interval||'!');
-- dbms_output.put_line('item_abccode  '||'!'||UPPER(p_item_rec.item_abccode)||'!');
-- dbms_output.put_line('gl_class   '||'!'||UPPER(p_item_rec.gl_class)||'!');
-- dbms_output.put_line('inv_class   '||'!'||UPPER(p_item_rec.inv_class)||'!');
-- dbms_output.put_line('sales_class  '||'!'||UPPER(p_item_rec.sales_class)||'!');
-- dbms_output.put_line('ship_class  '||'!'||UPPER(p_item_rec.ship_class)||'!');
-- dbms_output.put_line('frt_class   '||'!'||UPPER(p_item_rec.frt_class)||'!');
-- dbms_output.put_line('price_class  '||'!'||UPPER(p_item_rec.price_class)||'!');
-- dbms_output.put_line('storage_class  '||'!'||UPPER(p_item_rec.storage_class)||'!');
-- dbms_output.put_line('purch_class  '||'!'||UPPER(p_item_rec.purch_class)||'!');
-- dbms_output.put_line('tax_class   '||'!'||UPPER(p_item_rec.tax_class)||'!');
-- dbms_output.put_line('customs_class  '||'!'||UPPER(p_item_rec.customs_class)||'!');
-- dbms_output.put_line('alloc_class  '||'!'||UPPER(p_item_rec.alloc_class)||'!');
-- dbms_output.put_line('planning_class  '||'!'||UPPER(p_item_rec.planning_class)||'!');
-- dbms_output.put_line('itemcost_class  '||'!'||UPPER(p_item_rec.itemcost_class)||'!');
-- dbms_output.put_line('cost_mthd_code  '||'!'||UPPER(p_item_rec.cost_mthd_code)||'!');
-- dbms_output.put_line('upc_code   '||'!'||p_item_rec.upc_code||'!');
-- dbms_output.put_line('user_class1  '||'!'||p_item_rec.user_class1||'!');
-- dbms_output.put_line('user_class2  '||'!'||p_item_rec.user_class2||'!');
-- dbms_output.put_line('user_class3  '||'!'||p_item_rec.user_class3||'!');
-- dbms_output.put_line('user_class4  '||'!'||p_item_rec.user_class4||'!');
-- dbms_output.put_line('user_class5  '||'!'||p_item_rec.user_class5||'!');
-- dbms_output.put_line('user_class6  '||'!'||p_item_rec.user_class6||'!');
-- dbms_output.put_line('grade_ctl   '||'!'||p_item_rec.grade_ctl||'!');
-- dbms_output.put_line('status_ctl  '||'!'||p_item_rec.status_ctl||'!');
-- dbms_output.put_line('qc_grade   '||'!'||UPPER(p_item_rec.qc_grade)||'!');
-- dbms_output.put_line('lot_status  '||'!'||UPPER(p_item_rec.lot_status)||'!');
-- dbms_output.put_line('bulk_id   '||'!'||p_item_rec.bulk_id||'!');
-- dbms_output.put_line('pkg_id   '||'!'||p_item_rec.pkg_id||'!');
-- dbms_output.put_line('qcitem_id   '||'!'||l_qcitem_id||'!');
-- dbms_output.put_line('qchold_res_code  '||'!'||UPPER(p_item_rec.qchold_res_code)||'!');
-- dbms_output.put_line('expaction_code  '||'!'||UPPER(p_item_rec.expaction_code)||'!');
-- dbms_output.put_line('fill_qty   '||'!'||p_item_rec.fill_qty||'!');
-- dbms_output.put_line('fill_um   '||'!'||UPPER(p_item_rec.fill_um)||'!');
-- dbms_output.put_line('expaction_interval'||'!'||p_item_rec.expaction_interval||'!');
-- dbms_output.put_line('phantom_type  '||'!'||p_item_rec.phantom_type||'!');
-- dbms_output.put_line('whse_item_id  '||'!'||l_whse_item_id||'!');
-- dbms_output.put_line('experimental_ind  '||'!'||p_item_rec.experimental_ind||'!');
-- dbms_output.put_line('exported_date  '||'!'||GMA_GLOBAL_GRP.SY$MIN_DATE||'!');
-- dbms_output.put_line('date_added  '||'!'||SYSDATE||'!');
-- dbms_output.put_line('date_modified  '||'!'||SYSDATE||'!');
-- dbms_output.put_line('added_by   '||'!'||l_op_code||'!');
-- dbms_output.put_line('modified_by  '||'!'||l_op_code||'!');
-- dbms_output.put_line('trans_cnt   '||'!'||1||'!');
-- dbms_output.put_line('delete_mark  '||'!'||0||'!');
-- dbms_output.put_line('text_code   '||'!'||0||'!');
-- dbms_output.put_line('seq_dpnd_class  '||'!'||UPPER(p_item_rec.seq_dpnd_class)||'!');
-- dbms_output.put_line('commodity_code  '||'!'||p_item_rec.commodity_code||'!');
  IF NOT GMI_ITEM_PVT.insert_ic_item_mst(l_ic_item_mst_rec)
  THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

-- Set up PL/SQL record and insert item into ic_item_cpg

  l_ic_item_cpg_rec.item_id            := l_item_id;
  l_ic_item_cpg_rec.ic_matr_days       := p_item_rec.ic_matr_days;
  l_ic_item_cpg_rec.ic_hold_days       := p_item_rec.ic_hold_days;
  l_ic_item_cpg_rec.creation_date      := SYSDATE;
  l_ic_item_cpg_rec.last_update_date   := SYSDATE;
  l_ic_item_cpg_rec.created_by         := l_user_id;
  l_ic_item_cpg_rec.last_updated_by    := l_user_id;
  l_ic_item_cpg_rec.last_update_login  := TO_NUMBER(FND_PROFILE.Value(
                                        'LOGIN_ID'));
--B1231196 Don't write record to ic_item_cpg.  All parameters, variables etc
--associated with cpg tables should eventually be removed to save on
--processing time

-- IF NOT GMI_ITEM_PVT.insert_ic_item_cpg(l_ic_item_cpg_rec)
-- THEN
--   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
-- END IF;
--B1231196 End

-- Set up PL/SQL record and call lot create API
-- Set lot_no to 'NEWITEM' which will be replaced by
-- IC$DEFAULT_LOT in lot create API

  l_lot_rec.item_no          := l_item_no;
  l_lot_rec.lot_no           := 'NEWITEM';
  l_lot_rec.sublot_no        := NULL;
  l_lot_rec.expaction_date   := GMA_GLOBAL_GRP.SY$MIN_DATE;
  l_lot_rec.lot_created      := GMA_GLOBAL_GRP.SY$MIN_DATE;
  l_lot_rec.expire_date      := GMA_GLOBAL_GRP.SY$MAX_DATE;
  l_lot_rec.retest_date      := GMA_GLOBAL_GRP.SY$MIN_DATE;
  l_lot_rec.strength         := 100;
  l_lot_rec.inactive_ind     := 0;
  l_lot_rec.origination_type := 0;
  l_lot_rec.ic_matr_date     := GMA_GLOBAL_GRP.SY$MIN_DATE;
  l_lot_rec.ic_hold_date     := GMA_GLOBAL_GRP.SY$MIN_DATE;
  l_lot_rec.user_name        := l_user_name;

-- Call lot create API

   GMI_LOTS_PUB.create_lot (  p_api_version   => 2.0
                            , p_commit        => FND_API.G_FALSE
                            , p_init_msg_list => FND_API.G_FALSE
                            , x_return_status => l_return_status
                            , x_msg_count     => l_msg_count
                            , x_msg_data      => l_msg_data
                            , p_lot_rec       => l_lot_rec
                           );

-- If errors were found then raise exception
  IF (l_return_status = FND_API.G_RET_STS_ERROR)
  THEN
    RAISE FND_API.G_EXC_ERROR;
  ELSIF
    l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

-- END of API Body

-- Standard Check of p_commit.
  IF FND_API.to_boolean(p_commit)
  THEN
    COMMIT WORK;
  END IF;
  -- Success message
  FND_MESSAGE.SET_NAME('GMI','IC_API_ITEM_CREATED');
  FND_MESSAGE.SET_TOKEN('ITEM_NO', l_item_no);
  FND_MSG_PUB.Add;
-- Standard Call to get message count and if count is 1,
-- get message info.

  FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                             , p_data  =>  x_msg_data
                            );

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      ROLLBACK TO Create_Item;
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                                 , p_data  =>  x_msg_data
                                );

   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO Create_Item;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
      FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                                 , p_data  =>  x_msg_data
                                );
   WHEN OTHERS THEN
      ROLLBACK TO Create_Item;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
--       IF   FND_MSG_PUB.check_msg_level
--           (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--       THEN

     FND_MSG_PUB.Add_Exc_Msg (  G_PKG_NAME
                              , l_api_name
                             );
--      END IF;
      FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                                 , p_data  =>  x_msg_data
                                );
END Create_Item;

-- Api start of comments
--+==========================================================================+
--| PROCEDURE NAME                                                           |
--|    Validate_Item                                                         |
--|                                                                          |
--| TYPE                                                                     |
--|    Public                                                                |
--|                                                                          |

--| USAGE                                                                    |
--|    Perform all validation functions associated with creation of a new    |
--|    inventory item                                                        |
--|                                                                          |
--| DESCRIPTION                                                              |
--|    This procedure validates all data associated with creation of         |
--|    a new inventory item                                                  |
--|                                                                          |
--| PARAMETERS                                                               |
--|    p_api_version      IN  NUMBER       - Api Version                     |
--|    p_init_msg_list    IN  VARCHAR2     - Message Initialization Ind.     |
--|    p_commit           IN  VARCHAR2     - Commit Indicator                |
--|    p_validation_level IN  VARCHAR2     - Validation Level Indicator      |

--|    p_item_rec         IN  item_rec_typ - Item Master details             |
--|    x_return_status    OUT VARCHAR2     - Return Status                   |
--|    x_msg_count        OUT NUMBER       - Number of messages              |
--|    x_msg_data         OUT VARCHAR2     - Messages in encoded format      |
--|                                                                          |
--| RETURNS                                                                  |
--|    None                                                                  |
--|                                                                          |
--| HISTORY                                                                  |
--|                                                                          |
--+==========================================================================+
-- Api end of comments
PROCEDURE Validate_Item

( p_api_version      IN NUMBER
, p_init_msg_list    IN VARCHAR2 :=FND_API.G_FALSE
, p_validation_level IN VARCHAR2 :=FND_API.G_VALID_LEVEL_FULL
, p_item_rec         IN item_rec_typ
, x_return_status    OUT NOCOPY VARCHAR2
, x_msg_count        OUT NOCOPY NUMBER
, x_msg_data         OUT NOCOPY VARCHAR2
)
IS
l_api_name    CONSTANT VARCHAR2 (30) := 'Validate_Item';
l_api_version CONSTANT NUMBER        := 2.0;
l_item_id              ic_item_mst.item_id%TYPE;
l_item_no              ic_item_mst.item_no%TYPE;

l_item_desc1           ic_item_mst.item_desc1%TYPE;
l_item_um              ic_item_mst.item_um%TYPE;
l_item_um2             ic_item_mst.item_um2%TYPE;
l_qcitem_id            ic_item_mst.qcitem_id%TYPE;
l_whse_item_id         ic_item_mst.whse_item_id%TYPE;
l_user_name            fnd_user.user_name%TYPE;
l_msg_count            NUMBER;
l_msg_data             VARCHAR2(2000);
l_return_status        VARCHAR2(1);
l_ic_item_mst_rec      ic_item_mst%ROWTYPE;
l_ic_item_cpg_rec      ic_item_cpg%ROWTYPE;
--B965832(1) Add these 2 variables
l_lot_status           ic_item_mst.lot_status%TYPE;
l_qc_grade             ic_item_mst.qc_grade%TYPE;

BEGIN


-- Standard call to check for call compatibility.
  IF NOT FND_API.Compatible_API_CALL ( l_api_version
                                      , p_api_version
                                      , l_api_name
                                      , G_PKG_NAME
                                     )
  THEN
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

-- Initialize message list if p_int_msg_list is set TRUE.
  IF FND_API.to_boolean(p_init_msg_list)

  THEN
    FND_MSG_PUB.Initialize;
  END IF;
-- Initialize API return status to sucess
  x_return_status := FND_API.G_RET_STS_SUCCESS;

-- Ensure Upper-case columns are converted

  l_item_no    := UPPER(p_item_rec.item_no);
  l_item_um    := p_item_rec.item_um;
  l_item_um2   := p_item_rec.item_um2;
  l_user_name  := UPPER(p_item_rec.user_name);


-- Check item does not already exist
  IF (GMI_VALID_GRP.Validate_item_existance(l_item_no) <> 0)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_ITEM_ALREADY_EXISTS');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Check description
  IF (p_item_rec.item_desc1 = ' ' OR p_item_rec.item_desc1 IS NULL)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_ITEM_DESC1');

    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;


-- Primary Unit of Measure
 IF NOT GMA_VALID_GRP.Validate_um(l_item_um)
 THEN
  FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_UOM');
  FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
  FND_MESSAGE.SET_TOKEN('UOM',l_item_um);
  FND_MSG_PUB.Add;
  RAISE FND_API.G_EXC_ERROR;
 END IF;

-- Dual unit of measure indicator
  IF NOT GMI_VALID_GRP.Validate_dualum_ind(p_item_rec.dualum_ind)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_DUALUM_IND');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Secondary Unit of Measure

  IF NOT GMI_VALID_GRP.Validate_item_um2(p_item_rec.dualum_ind,l_item_um2)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_UOM');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MESSAGE.SET_TOKEN('UOM',l_item_um2);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Deviation factor lo
  IF NOT GMI_VALID_GRP.Validate_deviation (  p_item_rec.dualum_ind
                                           , p_item_rec.deviation_lo
                                          )

  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_DEVIATION');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Deviation factor hi
  IF NOT GMI_VALID_GRP.Validate_deviation (  p_item_rec.dualum_ind
                                           , p_item_rec.deviation_hi
                                          )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_DEVIATION');

    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- lot control flag
  IF NOT GMI_VALID_GRP.Validate_lot_ctl(p_item_rec.lot_ctl)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_LOT_CTL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;


-- lot indivisible flag
  IF NOT GMI_VALID_GRP.Validate_lot_indivisible (  p_item_rec.lot_ctl
                                                 , p_item_rec.lot_indivisible
                                                )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_LOT_INDIVISIBLE');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Sublot control flag

  IF NOT GMI_VALID_GRP.Validate_sublot_ctl (  p_item_rec.lot_ctl
                                            , p_item_rec.sublot_ctl
                                           )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_SUBLOT_CTL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Location control flag
  IF NOT GMI_VALID_GRP.Validate_loct_ctl(p_item_rec.loct_ctl)
  THEN

    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_LOCT_CTL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Non-inventory flag
  IF NOT GMI_VALID_GRP.Validate_noninv_ind (  p_item_rec.noninv_ind
                                            , p_item_rec.lot_ctl
                                           )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_NONINV_IND');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Match type
--  IF NOT GMI_VALID_GRP.Validate_Type( 'MATCH_TYPE'
--				    , p_item_rec.match_type)
 -- THEN
  --  FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_MATCH_TYPE');
   -- FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    --FND_MSG_PUB.Add;
   -- RAISE FND_API.G_EXC_ERROR;
 -- END IF;


-- Inactive indicator
  IF NOT GMI_VALID_GRP.Validate_inactive_ind(p_item_rec.inactive_ind)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_INACTIVE_IND');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Inventory Type
  IF (p_item_rec.inv_type <> ' ' AND p_item_rec.inv_type IS NOT NULL)
  THEN

    IF NOT GMI_VALID_GRP.Validate_inv_type(p_item_rec.inv_type)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_INV_TYPE');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Shelf Life
  IF NOT GMI_VALID_GRP.Validate_shelf_life (  p_item_rec.shelf_life
                                            , p_item_rec.grade_ctl
                                           )

  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_SHELF_LIFE');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Retest Interval
  IF NOT GMI_VALID_GRP.Validate_retest_interval (  p_item_rec.retest_interval
                                                 , p_item_rec.grade_ctl
                                                )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_RETEST_INTERVAL');

    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- GL class

  IF (p_item_rec.gl_class <> ' ' AND p_item_rec.gl_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_gl_class(p_item_rec.gl_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_GL_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Inventory class

  IF (p_item_rec.inv_class <> ' ' AND p_item_rec.inv_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_inv_class(p_item_rec.inv_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_INV_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Sales class

  IF (p_item_rec.sales_class <> ' ' AND p_item_rec.sales_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_sales_class(p_item_rec.sales_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_SALES_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Ship class

  IF (p_item_rec.ship_class <> ' ' AND p_item_rec.ship_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_ship_class(p_item_rec.ship_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_SHIP_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Freight class

  IF (p_item_rec.frt_class <> ' ' AND p_item_rec.frt_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_frt_class(p_item_rec.frt_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_FRT_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Price class

  IF (p_item_rec.price_class <> ' ' AND p_item_rec.price_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_price_class(p_item_rec.price_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_PRICE_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Storage class

  IF (p_item_rec.storage_class <> ' ' AND p_item_rec.storage_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_storage_class(p_item_rec.storage_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_STORAGE_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Purchase class

  IF (p_item_rec.purch_class <> ' ' AND p_item_rec.purch_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_purch_class(p_item_rec.purch_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_PURCH_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Tax class

  IF (p_item_rec.tax_class <> ' ' AND p_item_rec.tax_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_tax_class(p_item_rec.tax_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_TAX_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Customs class

  IF (p_item_rec.customs_class <> ' ' AND p_item_rec.customs_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_customs_class(p_item_rec.customs_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_CUSTOMS_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Allocation class

  IF (p_item_rec.alloc_class <> ' ' AND p_item_rec.alloc_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_alloc_class(p_item_rec.alloc_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_ALLOC_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Planning class

  IF (p_item_rec.planning_class <> ' ' AND
      p_item_rec.planning_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_planning_class(p_item_rec.planning_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_PLANNING_CLASS');

      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- item Cost class
  IF (p_item_rec.itemcost_class <> ' ' AND
      p_item_rec.itemcost_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_itemcost_class(p_item_rec.itemcost_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_ITEMCOST_CLASS');

      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Cost Method Code
  IF (p_item_rec.cost_mthd_code <> ' ' AND
      p_item_rec.cost_mthd_code IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_cost_mthd_code(p_item_rec.cost_mthd_code)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_COST_MTHD_CODE');

      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Grade control
  IF NOT GMI_VALID_GRP.Validate_grade_ctl (  p_item_rec.grade_ctl
                                           , p_item_rec.lot_ctl
                                          )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_GRADE_CTL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);

    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- lot status control
  IF NOT GMI_VALID_GRP.Validate_status_ctl (  p_item_rec.status_ctl
                                            , p_item_rec.lot_ctl
                                           )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_STATUS_CTL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;

  END IF;

-- QC Grade
--B965832(1) Add check for grade control status
  IF ((p_item_rec.grade_ctl=0) OR (p_item_rec.qc_grade= ' '))
  THEN
    l_qc_grade :='';
  ELSE
    l_qc_grade := UPPER(p_item_rec.qc_grade);
  END IF;
  IF NOT GMI_VALID_GRP.Validate_qc_grade (  l_qc_grade
                                          , p_item_rec.grade_ctl
                                         )
--B965832(1) end
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_QC_GRADE');
    FND_MESSAGE.SET_TOKEN('QC_GRADE',p_item_rec.qc_grade);
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;


-- lot Status

--B965832(1) Add these lines to check for status control

  IF ((p_item_rec.status_ctl = 0) OR (p_item_rec.lot_status=' '))
  THEN
    l_lot_status := '';
  ELSE
    l_lot_status := UPPER(p_item_rec.lot_status);
  END IF;
  IF NOT GMI_VALID_GRP.Validate_lot_status ( l_lot_status
                                            , p_item_rec.status_ctl
                                           )
--B965832(1) end
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_LOT_STATUS');
    FND_MESSAGE.SET_TOKEN('LOT_STATUS',p_item_rec.lot_status);
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;


-- QC reference item
  IF (p_item_rec.grade_ctl <> 1   AND
      p_item_rec.qcitem_no <> ' ' AND
      p_item_rec.qcitem_no IS NOT NULL)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_QCITEM_NO');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  ELSIF (p_item_rec.qcitem_no <> ' ' AND p_item_rec.qcitem_no IS NOT NULL)
  THEN
    GMI_GLOBAL_GRP.Get_Item (  p_item_no    => p_item_rec.qcitem_no
                             , x_ic_item_mst  => l_ic_item_mst_rec

                             , x_ic_item_cpg  => l_ic_item_cpg_rec
                            );
    IF (l_ic_item_mst_rec.item_id < 0)
    THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF (l_ic_item_mst_rec.item_id = 0) OR
	  (l_ic_item_mst_rec.delete_mark = 1)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_QCITEM_NO');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    ELSIF (l_ic_item_mst_rec.noninv_ind = 1)

    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_NONINV_ITEM_NO');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    ELSIF (l_ic_item_mst_rec.inactive_ind = 1)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INACTIVE_ITEM_NO');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;


-- QC Hold reason code
-- IF NOT GMI_VALID_GRP.Validate_qchold_res_code(p_item_rec.qchold_res_code,
       -- p_item_rec.qc_grade) THEN
    -- FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_QCHOLD_RES_CODE');
    -- FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    -- FND_MSG_PUB.Add;
    -- RAISE FND_API.G_EXC_ERROR;
-- END IF;

-- Expiry Action Code
  IF (p_item_rec.expaction_code <> ' ' AND
      p_item_rec.expaction_code IS NOT NULL)

  THEN
    IF NOT GMI_VALID_GRP.Validate_expaction_code (  p_item_rec.expaction_code
                                                  , p_item_rec.grade_ctl
                                                 )
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_EXPACTION_CODE');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Expiry Action Interval

  IF NOT GMI_VALID_GRP.Validate_expaction_interval(p_item_rec.expaction_interval


                                                  , p_item_rec.grade_ctl
						  )
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_EXPACTION_CODE');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Warehouse item no.


  IF (p_item_rec.whse_item_no <> ' ' AND p_item_rec.whse_item_no IS NOT NULL)
  THEN
    GMI_GLOBAL_GRP.Get_Item (  p_item_no    => p_item_rec.whse_item_no
                             , x_ic_item_mst  => l_ic_item_mst_rec
                             , x_ic_item_cpg  => l_ic_item_cpg_rec
                            );
    IF (l_ic_item_mst_rec.item_id < 0)
    THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF (l_ic_item_mst_rec.item_id = 0) OR
	  (l_ic_item_mst_rec.delete_mark = 1)
    THEN

      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_WHSE_ITEM_NO');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    ELSIF (l_ic_item_mst_rec.noninv_ind = 1)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_NONINV_ITEM_NO');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    ELSIF (l_ic_item_mst_rec.inactive_ind = 1)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INACTIVE_ITEM_NO');

      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;
  END IF;

-- Experimental Indicator
  IF NOT GMI_VALID_GRP.Validate_experimental_ind(p_item_rec.experimental_ind)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_EXPERIMENTAL');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;

  END IF;

-- Sequence Dependent class

  IF (p_item_rec.seq_dpnd_class <> ' ' AND
      p_item_rec.seq_dpnd_class IS NOT NULL)
  THEN
    IF NOT GMI_VALID_GRP.Validate_seq_dpnd_class(p_item_rec.seq_dpnd_class)
    THEN
      FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_SEQ_DPND_CLASS');
      FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
      FND_MSG_PUB.Add;
      RAISE FND_API.G_EXC_ERROR;

    END IF;
  END IF;

-- Maturity days (CPG)
  IF (NOT GMI_VALID_GRP.Validate_ic_matr_days(p_item_rec.ic_matr_days)               OR
     p_item_rec.ic_matr_days IS NULL)
  THEN
    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_MATR_DAYS');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

-- Hold release days (CPG)
  IF (NOT GMI_VALID_GRP.Validate_ic_hold_days(p_item_rec.ic_hold_days)               OR
     p_item_rec.ic_hold_days IS NULL)
  THEN

    FND_MESSAGE.SET_NAME('GMI','IC_API_INVALID_HOLD_DAYS');
    FND_MESSAGE.SET_TOKEN('ITEM_NO',l_item_no);
    FND_MSG_PUB.Add;
    RAISE FND_API.G_EXC_ERROR;
  END IF;

EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                               , p_data  =>  x_msg_data
                              );
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                               , p_data  =>  x_msg_data
                              );
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
--       IF   FND_MSG_PUB.check_msg_level
--           (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
--       THEN

    FND_MSG_PUB.Add_Exc_Msg ( G_PKG_NAME
                             , l_api_name
                            );

--      END IF;
    FND_MSG_PUB.Count_AND_GET (  p_count =>  x_msg_count
                               , p_data  =>  x_msg_data
                              );

END Validate_Item;
END GMI_ITEM_PUB;