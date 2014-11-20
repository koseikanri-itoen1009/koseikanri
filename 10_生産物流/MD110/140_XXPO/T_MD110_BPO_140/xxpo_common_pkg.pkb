create or replace PACKAGE BODY xxpo_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name           : xxpo_common_pkg(BODY)
 * Description            : ���ʊ֐�(BODY)
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐��i�⑫�����j.xls
 * Version                : 1.2
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  inventory_posting     P    -     �݌ɐ���API�iForms����̃R�[���p�j
 *  update_po             F    NUM   �����ύXAPI�iForms����̃R�[���p�j
 *  key_delrec_chk        F    NUM   �d���P���}�X�^�폜�O�`�F�b�N�����iForms����̃R�[���p�j
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/21   1.0   K.Aizawa         �V�K�쐬
 *  2008/04/08   1.1   K.Aizawa         �����ύXAPI��ǉ�
 *  2010/03/01   1.2   M.Miyagawa       �d���P���}�X�^�폜�O�`�F�b�N�����ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo_common_pkg'; -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Function Name    : inventory_posting
   * Description      : �݌ɐ���API�iForms����̃R�[���p�j
   ***********************************************************************************/
  PROCEDURE inventory_posting
  ( p_api_version           IN  NUMBER
  , p_init_msg_list         IN  VARCHAR2 DEFAULT FND_API.G_FALSE
  , p_commit                IN  VARCHAR2 DEFAULT FND_API.G_FALSE
  , p_validation_level      IN  NUMBER DEFAULT FND_API.G_VALID_LEVEL_FULL
  , p_trans_type            IN  NUMBER
  , p_item_no               IN  ic_item_mst.item_no%TYPE
  , p_journal_no            IN  ic_jrnl_mst.journal_no%TYPE
  , p_from_whse_code        IN  ic_tran_cmp.whse_code%TYPE
  , p_to_whse_code          IN  ic_tran_cmp.whse_code%TYPE  DEFAULT NULL
  , p_item_um               IN  ic_item_mst.item_um%TYPE    DEFAULT NULL
  , p_item_um2              IN  ic_item_mst.item_um2%TYPE   DEFAULT NULL
  , p_lot_no                IN  ic_lots_mst.lot_no%TYPE     DEFAULT NULL
  , p_sublot_no             IN  ic_lots_mst.sublot_no%TYPE  DEFAULT NULL
  , p_from_location         IN  ic_tran_cmp.location%TYPE   DEFAULT NULL
  , p_to_location           IN  ic_tran_cmp.location%TYPE   DEFAULT NULL
  , p_trans_qty             IN  ic_tran_cmp.trans_qty%TYPE  DEFAULT 0
  , p_trans_qty2            IN  ic_tran_cmp.trans_qty2%TYPE DEFAULT NULL
  , p_qc_grade              IN  ic_tran_cmp.qc_grade%TYPE   DEFAULT NULL
  , p_lot_status            IN  ic_tran_cmp.lot_status%TYPE DEFAULT NULL
  , p_co_code               IN  ic_tran_cmp.co_code%TYPE
  , p_orgn_code             IN  ic_tran_cmp.orgn_code%TYPE
  , p_trans_date            IN  ic_tran_cmp.trans_date%TYPE DEFAULT SYSDATE
  , p_reason_code           IN  ic_tran_cmp.reason_code%TYPE
  , p_user_name             IN  fnd_user.user_name%TYPE     DEFAULT 'OPM'
  , p_journal_comment       IN  ic_jrnl_mst.journal_comment%TYPE
  , p_attribute1            IN  ic_jrnl_mst.attribute1%TYPE          DEFAULT NULL
  , p_attribute2            IN  ic_jrnl_mst.attribute2%TYPE          DEFAULT NULL
  , p_attribute3            IN  ic_jrnl_mst.attribute3%TYPE          DEFAULT NULL
  , p_attribute4            IN  ic_jrnl_mst.attribute4%TYPE          DEFAULT NULL
  , p_attribute5            IN  ic_jrnl_mst.attribute5%TYPE          DEFAULT NULL
  , p_attribute6            IN  ic_jrnl_mst.attribute6%TYPE          DEFAULT NULL
  , p_attribute7            IN  ic_jrnl_mst.attribute7%TYPE          DEFAULT NULL
  , p_attribute8            IN  ic_jrnl_mst.attribute8%TYPE          DEFAULT NULL
  , p_attribute9            IN  ic_jrnl_mst.attribute9%TYPE          DEFAULT NULL
  , p_attribute10           IN  ic_jrnl_mst.attribute10%TYPE         DEFAULT NULL
  , p_attribute11           IN  ic_jrnl_mst.attribute11%TYPE         DEFAULT NULL
  , p_attribute12           IN  ic_jrnl_mst.attribute12%TYPE         DEFAULT NULL
  , p_attribute13           IN  ic_jrnl_mst.attribute13%TYPE         DEFAULT NULL
  , p_attribute14           IN  ic_jrnl_mst.attribute14%TYPE         DEFAULT NULL
  , p_attribute15           IN  ic_jrnl_mst.attribute15%TYPE         DEFAULT NULL
  , p_attribute16           IN  ic_jrnl_mst.attribute16%TYPE         DEFAULT NULL
  , p_attribute17           IN  ic_jrnl_mst.attribute17%TYPE         DEFAULT NULL
  , p_attribute18           IN  ic_jrnl_mst.attribute18%TYPE         DEFAULT NULL
  , p_attribute19           IN  ic_jrnl_mst.attribute19%TYPE         DEFAULT NULL
  , p_attribute20           IN  ic_jrnl_mst.attribute20%TYPE         DEFAULT NULL
  , p_attribute21           IN  ic_jrnl_mst.attribute21%TYPE         DEFAULT NULL
  , p_attribute22           IN  ic_jrnl_mst.attribute22%TYPE         DEFAULT NULL
  , p_attribute23           IN  ic_jrnl_mst.attribute23%TYPE         DEFAULT NULL
  , p_attribute24           IN  ic_jrnl_mst.attribute24%TYPE         DEFAULT NULL
  , p_attribute25           IN  ic_jrnl_mst.attribute25%TYPE         DEFAULT NULL
  , p_attribute26           IN  ic_jrnl_mst.attribute26%TYPE         DEFAULT NULL
  , p_attribute27           IN  ic_jrnl_mst.attribute27%TYPE         DEFAULT NULL
  , p_attribute28           IN  ic_jrnl_mst.attribute28%TYPE         DEFAULT NULL
  , p_attribute29           IN  ic_jrnl_mst.attribute29%TYPE         DEFAULT NULL
  , p_attribute30           IN  ic_jrnl_mst.attribute30%TYPE         DEFAULT NULL
  , p_attribute_category    IN  ic_jrnl_mst.attribute_category%TYPE  DEFAULT NULL
  , p_acctg_unit_no         IN  VARCHAR2  DEFAULT NULL
  , p_acct_no               IN  VARCHAR2  DEFAULT NULL
  , p_txn_type              IN  VARCHAR2  DEFAULT NULL
  , p_journal_ind           IN  VARCHAR2  DEFAULT NULL
  , p_move_entire_qty       IN  VARCHAR2  DEFAULT 'Y'
  , x_ic_jrnl_mst_row       OUT NOCOPY ic_jrnl_mst%ROWTYPE
  , x_ic_adjs_jnl_row1      OUT NOCOPY ic_adjs_jnl%ROWTYPE
  , x_ic_adjs_jnl_row2      OUT NOCOPY ic_adjs_jnl%ROWTYPE
  , x_return_status         OUT NOCOPY VARCHAR2
  , x_msg_count             OUT NOCOPY NUMBER
  , x_msg_data              OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inventory_posting'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���R�[�h�^ ***
    lt_qty_rec    GMIGAPI.qty_rec_typ;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
    -- �p�����[�^�ҏW
    lt_qty_rec.trans_type          := p_trans_type;
    lt_qty_rec.item_no             := p_item_no;
    lt_qty_rec.journal_no          := p_journal_no;
    lt_qty_rec.from_whse_code      := p_from_whse_code;
    lt_qty_rec.to_whse_code        := p_to_whse_code;
    lt_qty_rec.item_um             := p_item_um;
    lt_qty_rec.item_um2            := p_item_um2;
    lt_qty_rec.lot_no              := p_lot_no;
    lt_qty_rec.sublot_no           := p_sublot_no;
    lt_qty_rec.from_location       := p_from_location;
    lt_qty_rec.to_location         := p_to_location;
    lt_qty_rec.trans_qty           := p_trans_qty;
    lt_qty_rec.trans_qty2          := p_trans_qty2;
    lt_qty_rec.qc_grade            := p_qc_grade;
    lt_qty_rec.lot_status          := p_lot_status;
    lt_qty_rec.co_code             := p_co_code;
    lt_qty_rec.orgn_code           := p_orgn_code;
    lt_qty_rec.trans_date          := p_trans_date;
    lt_qty_rec.reason_code         := p_reason_code;
    lt_qty_rec.user_name           := p_user_name;
    lt_qty_rec.journal_comment     := p_journal_comment;
    lt_qty_rec.attribute1          := p_attribute1;
    lt_qty_rec.attribute2          := p_attribute2;
    lt_qty_rec.attribute3          := p_attribute3;
    lt_qty_rec.attribute4          := p_attribute4;
    lt_qty_rec.attribute5          := p_attribute5;
    lt_qty_rec.attribute6          := p_attribute6;
    lt_qty_rec.attribute7          := p_attribute7;
    lt_qty_rec.attribute8          := p_attribute8;
    lt_qty_rec.attribute9          := p_attribute9;
    lt_qty_rec.attribute10         := p_attribute10;
    lt_qty_rec.attribute11         := p_attribute11;
    lt_qty_rec.attribute12         := p_attribute12;
    lt_qty_rec.attribute13         := p_attribute13;
    lt_qty_rec.attribute14         := p_attribute14;
    lt_qty_rec.attribute15         := p_attribute15;
    lt_qty_rec.attribute16         := p_attribute16;
    lt_qty_rec.attribute17         := p_attribute17;
    lt_qty_rec.attribute18         := p_attribute18;
    lt_qty_rec.attribute19         := p_attribute19;
    lt_qty_rec.attribute20         := p_attribute20;
    lt_qty_rec.attribute21         := p_attribute21;
    lt_qty_rec.attribute22         := p_attribute22;
    lt_qty_rec.attribute23         := p_attribute23;
    lt_qty_rec.attribute24         := p_attribute24;
    lt_qty_rec.attribute25         := p_attribute25;
    lt_qty_rec.attribute26         := p_attribute26;
    lt_qty_rec.attribute27         := p_attribute27;
    lt_qty_rec.attribute28         := p_attribute28;
    lt_qty_rec.attribute29         := p_attribute29;
    lt_qty_rec.attribute30         := p_attribute30;
    lt_qty_rec.attribute_category  := p_attribute_category;
    lt_qty_rec.acctg_unit_no       := p_acctg_unit_no;
    lt_qty_rec.acct_no             := p_acct_no;
    lt_qty_rec.txn_type            := p_txn_type;
    lt_qty_rec.journal_ind         := p_journal_ind;
    lt_qty_rec.move_entire_qty     := p_move_entire_qty;
    --
    --
    -- �݌ɐ���API�R�[��
    GMIPAPI.Inventory_Posting
    ( p_api_version       -- IN  NUMBER
    , p_init_msg_list     -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_commit            -- IN  VARCHAR2 DEFAULT FND_API.G_FALSE
    , p_validation_level  -- IN  NUMBER DEFAULT FND_API.G_VALID_LEVEL_FULL
    , lt_qty_rec          -- IN  GMIGAPI.qty_rec_typ
    , x_ic_jrnl_mst_row   -- OUT NOCOPY ic_jrnl_mst%ROWTYPE
    , x_ic_adjs_jnl_row1  -- OUT NOCOPY ic_adjs_jnl%ROWTYPE
    , x_ic_adjs_jnl_row2  -- OUT NOCOPY ic_adjs_jnl%ROWTYPE
    , x_return_status     -- OUT NOCOPY VARCHAR2
    , x_msg_count         -- OUT NOCOPY NUMBER
    , x_msg_data          -- OUT NOCOPY VARCHAR2
    );
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END inventory_posting;
--
  /**********************************************************************************
   * Function Name    : update_po
   * Description      : �����ύXAPI�iForms����̃R�[���p�j
   ***********************************************************************************/
  FUNCTION update_po
 (
    x_po_number             IN  VARCHAR2
  , x_release_number        IN  NUMBER
  , x_revision_number       IN  NUMBER
  , x_line_number           IN  NUMBER
  , x_shipment_number       IN  NUMBER
  , new_quantity            IN  NUMBER
  , new_price               IN  NUMBER
  , new_promised_date       IN  DATE
  , launch_approvals_flag   IN  VARCHAR2
  , update_source           IN  VARCHAR2
  , version                 IN  VARCHAR2
  , x_override_date         IN  DATE := NULL
  , p_buyer_name            IN  VARCHAR2 DEFAULT NULL
  , p_module_name           IN  VARCHAR2 DEFAULT 'xxpo_common_pkg' -- �ďo�����W���[�����i���O�o�͗p�j
  , p_package_name          IN  VARCHAR2 DEFAULT 'po_update'       -- �ďo���p�b�P�[�W���i���O�o�͗p�j
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_po'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���R�[�h�^ ***
    x_api_errors           po_api_errors_rec_type;
    -- *** ���[�J���ϐ� ***
    ln_return_status       NUMBER;         -- �X�e�[�^�X
    lv_error_message       VARCHAR2(4000); -- ���O�e�[�u���o�͗p�G���[���b�Z�[�W
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- �����ύXAPI���R�[��
    ln_return_status :=
      PO_CHANGE_API1_S.Update_PO
      (
        x_po_number
      , x_release_number
      , x_revision_number
      , x_line_number
      , x_shipment_number
      , new_quantity
      , new_price
      , new_promised_date
      , launch_approvals_flag
      , update_source
      , version
      , x_override_date
      , x_api_errors
      , p_buyer_name
      );
--
    -- ��O�����̏ꍇ�AOUT�p�����[�^ x_api_errors.message_text �����O�e�[�u���ɏo��
    IF ( ln_return_status <> 1 ) THEN
      IF ( x_api_errors.message_name.COUNT > 0 ) THEN
        << x_api_errors_loop >>
        FOR i IN 1..x_api_errors.message_name.COUNT LOOP
          lv_error_message := ''; -- ���b�Z�[�W�ϐ�������
          -- ���̃��b�Z�[�W�̎擾
          lv_error_message := lv_error_message
                 || 'message_name    : ' || x_api_errors.message_name(i);
          lv_error_message := lv_error_message
                 || 'message_text    : ' || x_api_errors.message_text(i);
          lv_error_message := lv_error_message
                 || 'table_name      : ' || x_api_errors.table_name(i);
          lv_error_message := lv_error_message
                 || 'column_name     : ' || x_api_errors.column_name(i);
          lv_error_message := lv_error_message
                 || 'entity_type     : ' || x_api_errors.entity_type(i);
          lv_error_message := lv_error_message
                 || 'entity_id       : ' || TO_CHAR(x_api_errors.entity_id(i));
          lv_error_message := lv_error_message
                 || 'processing_date : ' || TO_CHAR(x_api_errors.processing_date(i)
                                            , 'YYYY/MM/DD-HH24:MI:SS');
          lv_error_message := lv_error_message
                 || 'message_type    : ' || x_api_errors.message_type(i);
--
          FND_LOG.STRING( 6
                        , p_module_name
                        , p_package_name
                        || lv_error_message );
--
        END LOOP x_api_errors_loop;
      END IF;
    END IF;
--
    -- �X�e�[�^�X�����^�[��
    RETURN ln_return_status;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
    RETURN 2;
--
--###################################  �Œ蕔 END   #########################################
--
  END update_po;
--
-- 2010-03-01 M.Miyagawa Add Start E_�{�ғ�_01315�Ή�
  /**********************************************************************************
   * Function Name    : key_delrec_chk
   * Description      : �d���P���}�X�^�폜�O�`�F�b�N�����iForms�R�[���p�j
   ***********************************************************************************/
  FUNCTION key_delrec_chk
 ( p_supply_to_id             IN VARCHAR2
 , p_item_id                  IN NUMBER
 , p_vendor_id                IN NUMBER
 , p_factory_code             IN VARCHAR2
 , p_futai_code               IN VARCHAR2
 , p_start_date_active        IN VARCHAR2
 , p_end_date_active          IN VARCHAR2
 ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'key_delrec_chk'; --�v���O������
--
    -- �ϐ��錾
    lv_select                   VARCHAR2(32000) ;
    lv_from                     VARCHAR2(32000) ;
    lv_where                    VARCHAR2(32000) ;
    lv_sql                      VARCHAR2(32000) ;     -- �f�[�^�����p�r�p�k
    lv_unit_price_calc_code     VARCHAR2(1)     ;     -- �d���P�����o���^�C�v�i�[�p
--
    -- ���[�J���E�J�[�\��
    TYPE        ref_cursor IS REF CURSOR ;
    lc_refcur   ref_cursor ;
    --���R�[�h�^�ϐ�
    TYPE        refcur_rect IS RECORD ( rec_count NUMBER ) ;
    refcur_rec  refcur_rect ;
--
  BEGIN
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    lv_select := '  SELECT '
              || 'COUNT(1)'
              ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := ' FROM'
            || ' po_headers_all       pha '
            || ',po_lines_all         pla '
            || ',xxcmn_item_mst_v     ximv '
            ;
-- �����敪:�x���Ɍ��� Start
    IF p_supply_to_id IS NOT NULL THEN
      lv_from := lv_from 
            || ',xxcmn_vendor_sites_v xvsv '
            || ',xxcmn_vendors_v      xvv '
            ;
    END IF;
-- �����敪:�x���Ɍ��� End
--
-- ��ʂ̕i��ID�����ɕi�ڃ}�X�^.�d���P�����o���^�C�v���擾
    SELECT ximv.unit_price_calc_code
    INTO   lv_unit_price_calc_code
    FROM   xxcmn_item_mst_v    ximv
    WHERE  ximv.item_id = p_item_id ;
--
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���������Ɍ��� Start
    IF lv_unit_price_calc_code = '1' THEN
      lv_from := lv_from 
            || ',ic_lots_mst          ilm '
            ;
    END IF;
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���������Ɍ��� End
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || '     pha.po_header_id = pla.po_header_id '
             || ' AND pla.item_id      = ximv.inventory_item_id '
             || ' AND pha.attribute1   <> ''99'' '
             || ' AND pla.cancel_flag  = ''N'' '
             || ' AND ximv.item_id     = ' || p_item_id      -- ���.OPM�i��ID
             || ' AND pha.vendor_id    = ' || p_vendor_id    -- ���.�����ID
             || ' AND pla.attribute2   = ' || '''' || p_factory_code || ''''  -- ���.�H��R�[�h
             || ' AND pla.attribute3   = ' || '''' || p_futai_code   || ''''  -- ���.�t�уR�[�h
             ;
-- �����敪:�x���Ɍ��� Start
    IF p_supply_to_id IS NOT NULL THEN
      lv_where := lv_where 
             || ' AND pha.attribute6   = ''3'' '         -- �����敪�F�x�� = �Œ�
             || ' AND xvv.vendor_div   = ''11'' '        -- �d����敪�F�x���� = �Œ�
             || ' AND xvsv.vendor_id   = xvv.vendor_id '
             || ' AND xvsv.vendor_site_code = pha.attribute7 '
             ;
    END IF;
-- �����敪:�x���Ɍ��� End
--
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���������Ɍ��� Start
    IF lv_unit_price_calc_code = '1' THEN
      lv_where := lv_where
             || ' AND ilm.item_id      = ximv.item_id '
             || ' AND ilm.lot_no       = pla.attribute1 '
             || ' AND ('
             || '        ( ximv.unit_price_calc_code = ''1'' ) ' -- �d���P�����o���^�C�v��������
             || '        AND
                        ( ( FND_DATE.STRING_TO_DATE( '''|| p_start_date_active ||''' , ''YYYY/MM/DD'' ) <= FND_DATE.STRING_TO_DATE( ilm.attribute1 , ''YYYY/MM/DD'' ))    
                          AND ( FND_DATE.STRING_TO_DATE( '''|| p_end_date_active ||''' , ''YYYY/MM/DD'' )   >= FND_DATE.STRING_TO_DATE( ilm.attribute1 , ''YYYY/MM/DD'' )) 
                        )
                      ) '
             ;
    END IF;
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���������Ɍ��� End
--
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���[�����Ɍ��� Start
    IF lv_unit_price_calc_code = '2' THEN
      lv_where := lv_where
             || ' AND ('
             || '        ( ximv.unit_price_calc_code = ''2'' ) ' -- �d���P�����o���^�C�v���[����
             || '        AND
                        ( ( FND_DATE.STRING_TO_DATE( '''|| p_start_date_active ||''', ''YYYY/MM/DD'' ) <= FND_DATE.STRING_TO_DATE( pha.attribute4 , ''YYYY/MM/DD'' ))            
                          AND ( FND_DATE.STRING_TO_DATE( '''|| p_end_date_active ||''' , ''YYYY/MM/DD'' )   >= FND_DATE.STRING_TO_DATE( pha.attribute4 , ''YYYY/MM/DD'' )) 
                        )  
                      ) '
             ;
    END IF;
-- �i�ڃ}�X�^.�d���P�����o���^�C�v���[�����Ɍ��� End
--
    lv_where := lv_where
           || ' AND  rownum = 1 '
           ; 
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_select || lv_from || lv_where  ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN lc_refcur FOR lv_sql ;
    -- �t�F�b�`
    FETCH lc_refcur INTO refcur_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_refcur ;
--
    RETURN refcur_rec.rec_count;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
    RETURN 2;
--
--###################################  �Œ蕔 END   #########################################
--
  END key_delrec_chk;
-- 2010-03-01 M.Miyagawa Add End
END xxpo_common_pkg;
