CREATE OR REPLACE PACKAGE BODY xxcmn790002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790002c(body)
 * Description      : �����i�����v�Z����
 * MD.050           : ���b�g�ʎ��ی����v�Z T_MD050_BPO_790
 * MD.070           : �����i�����v�Z���� T_MD070_BPO_79B
 * Version          : 1.4
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  get_opening_period           �݌ɃI�[�v�����Ԏ擾����(B-1)
 *  get_row_materials            �����i�f�[�^���o����(B-5)
 *  set_decition_unit_price      �����i�P���m�菈��(B-7)
 *  get_inject_prod_unit_price   �����i�P���m�菈��(B-8)
 *  ins_table_batch              �����i�f�[�^�o�^����(B-9)
 *  get_data_dump                �f�[�^�_���v�擾����
 *  put_success_dump             �����f�[�^�_���v�o�͏���
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/13     1.0   Y.Kanami         �V�K�쐬
 *  2008/04/25    1.2   Marushita        TE080_BPO_790 �s�ID 1
 *  2008/06/03    1.3   Marushita        TE080_BPO_790 �s�ID 1
 *  2008/07/03    1.4   Marushita        ST�s�314�Ή�
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;          -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;          -- �X�L�b�v����
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
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790002c';  -- �p�b�P�[�W��
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';         -- ���W���[�����ȗ��FXXCMN�}�X�^����
--
  gv_msg_xxcmn10039 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10039';
                                            -- ���b�Z�[�W�F�I�[�v�����Ԏ擾�G���[
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- ���b�Z�[�W�F�f�[�^�擾�G���[
  gv_msg_xxcmn10002 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10002';  
                                            -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
  gv_tkn_ng_profile CONSTANT VARCHAR2(100)  := 'NG_PROFILE';
                                            -- �g�[�N���FNG_PROFILE
--
  gv_doc_type_prod    CONSTANT VARCHAR2(100)  := 'PROD';  -- �����^�C�v�F���Y
  gn_completion       CONSTANT NUMBER         := 1;       -- �����敪�F����
  gn_l_type_finished  CONSTANT NUMBER         := 1;       -- ���׃^�C�v�F�����i
  gn_l_type_product   CONSTANT NUMBER         := 2;       -- ���׃^�C�v�F���Y��
  gn_l_type_materials CONSTANT NUMBER         := -1;      -- ���׃^�C�v�F�����i
  gv_real_cost_price  CONSTANT VARCHAR2(1)    := '0';     -- ���ی����F0
  gv_standard_cost    CONSTANT VARCHAR2(1)    := '1';     -- �W�������F1
  gn_cmpcls_material  CONSTANT NUMBER         := 1;       -- �R���|�[�l���g�敪�F����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �f�[�^�_���v�p���R�[�h�^
  TYPE data_dump_rtype IS RECORD(
      batch_id    xxcmn_txn_lot_cost.doc_id%TYPE      -- �o�b�`ID
    , trans_date  ic_tran_pnd.trans_date%TYPE         -- �����
    , item_id     xxcmn_txn_lot_cost.item_id%TYPE     -- �i��ID
    , item_code   xxcmn_txn_lot_cost.item_code%TYPE   -- �i�ڃR�[�h
    , lot_id      xxcmn_txn_lot_cost.lot_id%TYPE      -- ���b�gID
    , lot_num     xxcmn_txn_lot_cost.lot_num%TYPE     -- ���b�gNO
    , trans_qty   xxcmn_txn_lot_cost.trans_qty%TYPE   -- �������
    , unit_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- �����i�P��
  );
--
  -- �����iPL/SQL�\���R�[�h
  TYPE row_materials_rtype IS RECORD(
      item_id               xxcmn_item_mst_v.item_id%TYPE       -- �i��ID
    , lot_id                ic_lots_mst.lot_id%TYPE             -- ���b�gID
    , materials_qty         ic_tran_pnd.trans_qty%TYPE          -- ��������
    , materials_unit_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- �����i�P��
    , materials_cost_price  NUMBER  -- �����i�����F��������*�����i�P��
  );
--
  -- �����iPL/SQL�\�^
  TYPE row_materials_ttype IS TABLE OF row_materials_rtype INDEX BY BINARY_INTEGER;
--
  -- �����iPL/SQL�\�p���R�[�h�^
  TYPE half_finish_goods_rtype IS RECORD(
      batch_id        ic_tran_pnd.doc_id%TYPE             -- �o�b�`ID
    , trans_date      ic_tran_pnd.trans_date%TYPE         -- �����
    , item_id         xxcmn_item_mst_v.item_id%TYPE       -- �i��ID
    , item_no         xxcmn_item_mst_v.item_no%TYPE       -- �i�ڃR�[�h
    , lot_id          ic_lots_mst.lot_id%TYPE             -- ���b�gID
    , lot_no          ic_lots_mst.lot_no%TYPE             -- ���b�gNO
    , trans_qty       ic_tran_pnd.trans_qty%TYPE          -- �������
    , by_prod_qty     ic_tran_pnd.trans_qty%TYPE          -- ���Y���������
    , by_prod_price   cm_cmpt_dtl.cmpnt_cost%TYPE         -- ���Y���P��
    , half_fin_price  xxcmn_txn_lot_cost.unit_price%TYPE  -- �����i�P��
    , row_materials   row_materials_ttype                 -- �����iPL/SQL�\�^
  );
--
  -- �����iPL/SQL�\�^
  TYPE half_finish_goods_ttype IS TABLE OF half_finish_goods_rtype INDEX BY BINARY_INTEGER;
--
  -- �m��f�[�^PL/SQL�\�^
  TYPE doc_id_ttype       IS TABLE OF xxcmn_txn_lot_cost.doc_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ����ID
  TYPE trans_date_ttype   IS TABLE OF ic_tran_pnd.trans_date%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ������t
  TYPE item_id_ttype      IS TABLE OF xxcmn_txn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �i��ID
  TYPE item_code_ttype    IS TABLE OF xxcmn_txn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �i�ڃR�[�h
  TYPE lot_id_ttype       IS TABLE OF xxcmn_txn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ���b�gID
  TYPE lot_num_ttype      IS TABLE OF xxcmn_txn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- ���b�gNo
  TYPE trans_qty_ttype    IS TABLE OF xxcmn_txn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �������
  TYPE unit_price_ttype   IS TABLE OF xxcmn_txn_lot_cost.unit_price%TYPE INDEX BY BINARY_INTEGER;
                                                                                -- �P��
--
  -- �����i�P���m��`�F�b�N�pPL/SQL�\�^
  TYPE decision_chk_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_whse_code        xxcmn_item_locations_v.whse_code%TYPE;  -- �q�ɃR�[�h
  gd_opening_date     DATE;                                   -- �݌ɃI�[�v������
  gn_index_cnt        NUMBER  DEFAULT 0;                      -- �����i�擾�f�[�^�J�E���g
  gn_decision_cnt     NUMBER  DEFAULT 0;                      -- �m��f�[�^�J�E���g
  gn_row_material_cnt NUMBER  DEFAULT 0;                      -- �����i�f�[�^�J�E���g
--
  -- �����iPL/SQL�\
  gt_half_finish_goods_tab  half_finish_goods_ttype;
--
  -- �m��f�[�^PL/SQL�\
  gt_doc_id_ins_tab     doc_id_ttype;       -- ����ID
  gt_trans_date_ins_tab trans_date_ttype;   -- �����
  gt_item_id_ins_tab    item_id_ttype;      -- �i��ID
  gt_item_code_ins_tab  item_code_ttype;    -- �i�ڃR�[�h
  gt_lot_id_ins_tab     lot_id_ttype;       -- ���b�gID
  gt_lot_num_ins_tab    lot_num_ttype;      -- ���b�gNo
  gt_trans_qty_ins_tab  trans_qty_ttype;    -- �������
  gt_unit_price_ins_tab unit_price_ttype;   -- �P��
--
  /**********************************************************************************
   * Procedure Name   : get_opening_period
   * Description      : �݌ɃI�[�v�����Ԏ擾����(B-1)
   ***********************************************************************************/
  PROCEDURE get_opening_period(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_opening_period'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_whse_code      CONSTANT VARCHAR2(100)  := 'XXCMN_COST_PRICE_WHSE_CODE';  -- PROFILE:�����q��
    cv_whse_code_name CONSTANT VARCHAR2(100)  := 'XXCMN:�����q��';              -- PROFILE��:�����q��
    cv_yes            CONSTANT VARCHAR2(1)    := 'Y';                           -- YES
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================
    -- �q�ɃR�[�h���擾
    -- =====================================
    gt_whse_code  :=  FND_PROFILE.VALUE(cv_whse_code);
    IF (gt_whse_code IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10002   -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                   ,gv_tkn_ng_profile   -- �g�[�N���FNG�v���t�@�C����
                   ,cv_whse_code_name   -- �����q��
                   ),1,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
    -- =====================================
    -- ��v���ԊJ�n�����擾
    -- =====================================
    SELECT  MIN(oap.period_start_date)                        -- ��v���ԊJ�n��
    INTO    gd_opening_date
    FROM    org_acct_periods       oap,                       -- �݌ɉ�v����
            xxcmn_item_locations_v ilv                        -- OPM�ۊǏꏊ���VIEW
    WHERE   ilv.whse_code        = gt_whse_code               -- �q�ɃR�[�h
    AND     oap.organization_id  = ilv.mtl_organization_id    -- �g�DID
    AND     oap.open_flag        = cv_yes                     -- �I�[�v���t���O
    ;
    IF (gd_opening_date IS NULL) THEN
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN �}�X�^�E�o������
                   ,gv_msg_xxcmn10039   -- ���b�Z�[�W�FAPP-XXCMN-10039 �I�[�v�����Ԏ擾�G���[
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_opening_period;
--
  /**********************************************************************************
   * Procedure Name   : get_row_materials
   * Description      : �����i�f�[�^���o����(B-5)
   ***********************************************************************************/
  PROCEDURE get_row_materials(
    in_batch_id   IN  ic_tran_pnd.doc_id%TYPE,  -- �o�b�`ID
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_row_materials'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_item_div_material  CONSTANT VARCHAR2(1)  :=  '2';  -- �i�ڋ敪�F����
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt             NUMBER DEFAULT 0;     -- �f�[�^�J�E���^
    ln_data_cnt             NUMBER DEFAULT 0;     -- �f�[�^�J�E���^
    ln_cost_price           NUMBER DEFAULT NULL;  -- �����i����
    ln_sum_cost_price       NUMBER DEFAULT 0;     -- �����i�������Z
    ln_half_fin_unit_price  NUMBER DEFAULT 0;     -- �����i�P��
    ln_by_prod_cost_price   NUMBER DEFAULT 0;     -- ���Y������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �����i�f�[�^�擾
    CURSOR row_materials_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
      SELECT  ximv.item_id              item_id             -- �i��ID
            , itp.lot_id                lot_id              -- ���b�gID
            , SUM(itp.trans_qty)        trans_qty           -- ��������
            , xtlc.unit_price           unit_price          -- �P��
      FROM    ic_tran_pnd               itp                 -- �ۗ��݌Ƀg�����U�N�V����
            , xxcmn_item_mst_v          ximv                -- OPM�i�ڏ��View
            , xxcmn_txn_lot_cost        xtlc                -- ����ʃ��b�g�ʌ����i�A�h�I���j
            , xxcmn_item_categories4_v  xic                 -- OPM�i�ڃJ�e�S���������VIEW4
      WHERE itp.doc_id            =   batch_id              -- �o�b�`ID
      AND   itp.doc_type          =   gv_doc_type_prod      -- �����^�C�v�F���Y
      AND   itp.completed_ind     =   gn_completion         -- �����敪�F����
      AND   itp.line_type         =   gn_l_type_materials   -- ���׃^�C�v�F�����i
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id          -- �i��ID
      AND   ximv.cost_manage_code =   gv_real_cost_price    -- �����Ǘ��敪�F���ی���
      AND   itp.item_id           =   xtlc.item_id(+)       -- �i��ID
      AND   itp.lot_id            =   xtlc.lot_id(+)        -- ���b�gID
      AND   itp.item_id           =   xic.item_id           -- �i��ID
      AND   xic.item_class_code   <>  cv_item_div_material  -- �i�ڋ敪�F���ވȊO
      GROUP BY 
              ximv.item_id
            , itp.lot_id
            , xtlc.unit_price
      UNION ALL
      SELECT  ximv.item_id                item_id           -- �i��ID
            , itp.lot_id                  lot_id            -- ���b�gID
            , NVL(SUM(itp.trans_qty),0)   trans_qty         -- ��������
            , ccd.cmpnt_cost              unit_price        -- �P��
      FROM    ic_tran_pnd               itp                 -- �ۗ��݌Ƀg�����U�N�V����
            , xxcmn_item_mst_v          ximv                -- OPM�i�ڏ��View
            , (SELECT cc.calendar_code          calendar_code
                     ,cc.item_id                item_id
                     ,NVL(SUM(cc.cmpnt_cost),0) cmpnt_cost
               FROM  cm_cmpt_dtl cc
               WHERE cc.whse_code =   gt_whse_code
               GROUP BY calendar_code,item_id ) ccd         -- �W�������}�X�^
            , cm_cldr_hdr_b             clh                 -- �����J�����_�w�b�_
            , cm_cldr_dtl               cll                 -- �����J�����_����
            , xxcmn_item_categories4_v  xic                 -- OPM�i�ڃJ�e�S���������VIEW4
      WHERE itp.doc_id            =   batch_id              -- �o�b�`ID
      AND   itp.doc_type          =   gv_doc_type_prod      -- �����^�C�v�F���Y
      AND   itp.completed_ind     =   gn_completion         -- �����敪�F����
      AND   itp.line_type         =   gn_l_type_materials   -- ���׃^�C�v�F�����i
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id          -- �i��ID
      AND   ximv.cost_manage_code =   gv_standard_cost      -- �����Ǘ��敪�F�W������
      AND   itp.item_id           =   ccd.item_id           -- �i��ID
      AND   ccd.calendar_code     =   clh.calendar_code     -- �����J�����_�[�R�[�h
      AND   clh.calendar_code     =   cll.calendar_code     -- �����J�����_�[�R�[�h
      AND   itp.trans_date        >=  cll.start_date        -- ���ԁi���j
      AND   itp.trans_date        <=  cll.end_date          -- ���ԁi���j
      AND   itp.item_id           =   xic.item_id           -- �i��ID
      AND   xic.item_class_code   <>  cv_item_div_material  -- �i�ڋ敪�F���ވȊO
      GROUP BY
              ximv.item_id
            , itp.lot_id
            , ccd.cmpnt_cost
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=================================
    -- B-6.�����i�f�[�^�i�[����
    --=================================
    <<get_materials_loop>>
    FOR materials_loop IN row_materials_cur(in_batch_id) LOOP
--
      ln_loop_cnt := ln_loop_cnt + 1;
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).item_id
          := materials_loop.item_id;                                                -- �i��ID
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).lot_id
          := materials_loop.lot_id;                                                 -- ���b�gID
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_qty
          := materials_loop.trans_qty * -1;                                         -- ��������*-1
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_unit_price
          := materials_loop.unit_price;                                             -- �����i�P��
      gt_half_finish_goods_tab(gn_index_cnt).row_materials(ln_loop_cnt).materials_cost_price
          := materials_loop.unit_price * materials_loop.trans_qty * -1;             -- �����i����
--
    END LOOP get_meterials_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_row_materials;
  /**********************************************************************************
   * Procedure Name   : set_decition_unit_price
   * Description      : �����i�P���m�菈��(B-7)
   ***********************************************************************************/
  PROCEDURE set_decition_unit_price(
    in_index_cnt  IN          NUMBER,         -- INDEX�J�E���^
    ov_errbuf     OUT NOCOPY  VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_decition_unit_price'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_item_div_material  CONSTANT VARCHAR2(1)  :=  '2';  -- �i�ڋ敪�F����
--
    -- *** ���[�J���ϐ� ***
    ln_data_cnt             NUMBER DEFAULT 0;     -- �f�[�^�J�E���^
    ln_cost_price           NUMBER DEFAULT NULL;  -- �����i����
    ln_sum_cost_price       NUMBER DEFAULT 0;     -- �����i�������Z
    ln_half_fin_unit_price  NUMBER DEFAULT 0;     -- �����i�P��
    ln_by_prod_cost_price   NUMBER DEFAULT 0;     -- ���Y������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �����i�������m�肵�����m�F
    <<unit_price_decision_loop>>
    FOR i IN 1..gt_half_finish_goods_tab(in_index_cnt).row_materials.COUNT LOOP
      ln_data_cnt :=  ln_data_cnt + 1;
      -- �����i�����擾
      ln_cost_price :=  gt_half_finish_goods_tab(in_index_cnt)
                        .row_materials(ln_data_cnt)
                        .materials_cost_price;
--
      IF (ln_cost_price IS NULL) THEN
        ln_sum_cost_price  := NULL;
        EXIT;
      ELSE
        -- ���Z����
        ln_sum_cost_price := ln_sum_cost_price + ln_cost_price;
      END IF;
    END LOOP unit_price_decision_loop;
--
    -- �����i�����݂���ꍇ
    IF (ln_data_cnt > 0) THEN
--
      -- �S�Ă̓����i�������m�肵���ꍇ
      IF (ln_sum_cost_price IS NOT NULL) THEN
        -- =================================
        -- �����i�P���v�Z����
        -- =================================
        -- ���Y���������Z�o����
        ln_by_prod_cost_price :=  gt_half_finish_goods_tab(in_index_cnt).by_prod_price  
                                                                          -- ���Y���P��
                                  * gt_half_finish_goods_tab(in_index_cnt).by_prod_qty;
                                                                          -- ���Y���������
--
        -- �����i�P�����Z�o����
        IF (gt_half_finish_goods_tab(in_index_cnt).trans_qty = 0) THEN
          -- ������ʂ�0�̏ꍇ
          ln_half_fin_unit_price  := 0;
        ELSE
          ln_half_fin_unit_price  := ROUND((ln_sum_cost_price - ln_by_prod_cost_price)
                                                                          -- �����i���� - ���Y������
                                      / gt_half_finish_goods_tab(in_index_cnt).trans_qty, 2);
                                                                          -- �������
        END IF;
--
        -- �����iPL/SQL�\�̔����i�P���ɃZ�b�g����
        gt_half_finish_goods_tab(in_index_cnt).half_fin_price :=  ln_half_fin_unit_price;
--
        -- =================================
        -- �����i�������m�菈��
        -- =================================
        gn_decision_cnt :=  gn_decision_cnt + 1;  -- �m��f�[�^�J�E���g
        -- �m��f�[�^PL/SQL�\�Ɋi�[����
        gt_doc_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).batch_id;       -- ����ID
        gt_trans_date_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).trans_date;     -- �����                                      -- �����^�C�v
        gt_item_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).item_id;        -- �i��ID
        gt_item_code_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).item_no;        -- �i�ڃR�[�h
        gt_lot_id_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).lot_id;         -- ���b�gID
        gt_lot_num_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).lot_no;         -- ���b�gNO
        gt_trans_qty_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).trans_qty;      -- �������
        gt_unit_price_ins_tab(gn_decision_cnt)
                              := gt_half_finish_goods_tab(in_index_cnt).half_fin_price; -- �P��
--
      END IF;
--
      -- �����f�[�^�J�E���g
      gn_normal_cnt := gn_decision_cnt;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_decition_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : get_inject_prod_unit_price
   * Description      : �����i�P���m�菈��(B-8)
   ***********************************************************************************/
  PROCEDURE get_inject_prod_unit_price(
    ov_errbuf     OUT NOCOPY  VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY  VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY  VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inject_prod_unit_price'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_decision           CONSTANT NUMBER := 1; -- �P���m��
    cn_non_decision       CONSTANT NUMBER := 0; -- �P�����m��
    cn_no_change          CONSTANT NUMBER := 0; -- �ύX�Ȃ�
    cn_change             CONSTANT NUMBER := 1; -- �ύX����
    cn_first              CONSTANT NUMBER := 1; -- ����
    cn_second             CONSTANT NUMBER := 2; -- �Q���
--
    -- *** ���[�J���ϐ� ***
    lt_pre_chk_tab        decision_chk_ttype;           -- �O��`�F�b�N
    lt_curr_chk_tab       decision_chk_ttype;           -- ����`�F�b�N
    ln_half_fin_goods_cnt NUMBER DEFAULT 0;             -- �����i�Ǎ��J�E���^
    lb_decition_flag      BOOLEAN DEFAULT TRUE;         -- �P���m��t���O
    ln_change_flag        NUMBER DEFAULT cn_no_change;  -- �ύX�`�F�b�N�t���O
    ln_chk_cnt            NUMBER DEFAULT 0;             -- ���[�v�񐔃`�F�b�N
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �P���m��`�F�b�N�pPL/SQL�\������
    lt_pre_chk_tab.DELETE;
    lt_curr_chk_tab.DELETE;
--
    -- �����i�f�[�^�Ǎ�
    <<half_finish_goods_loop>>
    LOOP
--
      ln_half_fin_goods_cnt :=  ln_half_fin_goods_cnt + 1;
--
      -- �����i�P�������m��̏ꍇ
      IF (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).half_fin_price IS NULL) THEN
--
        -- �����i�f�[�^�Ǎ�
        <<row_materials_loop>>
        FOR ln_cnt_2 IN 1..gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials.COUNT LOOP
--
          -- �����i���������m��̏ꍇ
          IF (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2)
              .materials_cost_price IS NULL) THEN
--
            -- �m��f�[�^PL/SQL�\�Ǎ�
            <<decition_data_loop>>
            FOR ln_cnt_3 IN 1..gt_doc_id_ins_tab.COUNT LOOP
--
              -- �m��f�[�^�ɕi��ID�A���b�gID����v����f�[�^�����݂���ꍇ
              IF (
                    (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2).item_id 
                      = gt_item_id_ins_tab(ln_cnt_3))                                   -- �i��ID
                AND
                    (gt_half_finish_goods_tab(ln_half_fin_goods_cnt).row_materials(ln_cnt_2).lot_id
                      = gt_lot_id_ins_tab(ln_cnt_3))                                    -- ���b�gID
                 )                                    
              THEN
--
                -- �P���𓊓��iPL/SQL�\�̓����i�P���ɃZ�b�g����
                gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_unit_price 
                :=  gt_unit_price_ins_tab(ln_cnt_3);                              -- �P��
--
                -- �P��*���ʂ𓊓��iPL/SQL�\�̓����i�����ɃZ�b�g����
                gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_cost_price 
                := gt_half_finish_goods_tab(ln_half_fin_goods_cnt)
                  .row_materials(ln_cnt_2).materials_qty * gt_unit_price_ins_tab(ln_cnt_3);  
                                                                                  -- �����i����
--
              END IF;
--
            END LOOP decition_data_loop;
--
          END IF;
--
        END LOOP row_materials_loop;
--
        --=================================
        -- B-7.�����i�P���m�菈��
        --=================================
        set_decition_unit_price(
            in_index_cnt  =>  ln_half_fin_goods_cnt -- �f�[�^�J�E���^
          , ov_errbuf     =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode    =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg     =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �G���[�̏ꍇ�͏����I��
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;

--
      END IF;
--
      -- �Ō�܂œǂݍ��񂾏ꍇ
      IF (ln_half_fin_goods_cnt = gn_index_cnt) THEN
        <<chk_unit_price_loop>>
        -- �����i�̒P�����S�Ċm�肵�����m�F����
        FOR i IN 1..gn_index_cnt LOOP
          -- ���m��̒P�������݂����ꍇ
          IF (gt_half_finish_goods_tab(i).half_fin_price IS NULL) THEN
--
            -- �m��t���O�𖢊m��ɂ���
            lb_decition_flag  := FALSE;
--
            -- ����`�F�b�NPL/SQL�\�ɖ��m����Z�b�g
            lt_curr_chk_tab(i)  := cn_non_decision; -- ���m��
          ELSE
            -- ����`�F�b�NPL/SQL�\�Ɋm����Z�b�g
            lt_curr_chk_tab(i)  := cn_decision;     -- �m��
          END IF;
--
        END LOOP chk_unit_price_loop;
--
        IF (lb_decition_flag) THEN
          -- �S�Ă̔����i�P�����m�肵���ꍇ
          EXIT;
        ELSE
          -- �`�F�b�N�񐔂��Z�b�g
          ln_chk_cnt := ln_chk_cnt + 1;
--
          -- �����i�Ǎ��J�E���^���Z�b�g
          ln_half_fin_goods_cnt := 0;
          -- �m��t���O�����Z�b�g
          lb_decition_flag := TRUE;
--
          IF (ln_chk_cnt = cn_first) THEN
--
            <<set_loop_1>>
            FOR cnt_1 IN 1..gn_index_cnt LOOP
              -- ����̃`�F�b�N���ʂ�O��`�F�b�N�ɃZ�b�g����
              lt_pre_chk_tab(cnt_1) := lt_curr_chk_tab(cnt_1);
            END LOOP set_loop_1;
            -- ����`�F�b�NPL/SQL�\��������
            lt_curr_chk_tab.DELETE;
--
          ELSIF (ln_chk_cnt >= cn_second) THEN
            <<chk_loop>>
            FOR cnt_2 IN 1..gn_index_cnt LOOP
--
              IF (lt_pre_chk_tab(cnt_2) <> lt_curr_chk_tab(cnt_2)) THEN
--
                ln_change_flag := cn_change;
                -- 1�ӏ��ł��ύX�ӏ�������΃��[�v�𔲂���
                EXIT;
              END IF;
            END LOOP chk_loop;
--
            -- �O����m�肳�ꂽ�P�������݂���ꍇ
            IF (ln_change_flag = cn_change) THEN
              -- �O��`�F�b�NPL/SQL�\��������
              lt_pre_chk_tab.DELETE;
              -- ����̃`�F�b�N���ʂ�O��`�F�b�N���ʂɃZ�b�g����
              <<set_loop_2>>
              FOR cnt_3 IN 1..gn_index_cnt LOOP
                -- ����̃`�F�b�N���ʂ�O��`�F�b�N�ɃZ�b�g����
                lt_pre_chk_tab(cnt_3) := lt_curr_chk_tab(cnt_3);
              END LOOP set_loop_2;
              -- ����`�F�b�NPL/SQL�\��������
              lt_curr_chk_tab.DELETE;
              -- �ύX�`�F�b�N�t���O�����Z�b�g
              ln_change_flag := cn_no_change;
--
            ELSE
              -- �O��ƕύX���Ȃ��ꍇ�͏������I������
              EXIT;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP half_finish_goods_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_inject_prod_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : ins_table_batch
   * Description      : �����i�f�[�^�o�^����(B-9)
   ***********************************************************************************/
  PROCEDURE ins_table_batch(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_table_batch'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_user_id          xxcmn_txn_lot_cost.created_by%TYPE;             -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         xxcmn_txn_lot_cost.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
    lt_conc_request_id  xxcmn_txn_lot_cost.request_id%TYPE;             -- �v��ID
    lt_prog_appl_id     xxcmn_txn_lot_cost.program_application_id%TYPE; -- �A�v���P�[�V����ID
    lt_conc_program_id  xxcmn_txn_lot_cost.program_id%TYPE;             -- �v���O����ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- WHO�J�����擾
    lt_user_id          := FND_GLOBAL.USER_ID;          -- �쐬�ҁA�ŏI�X�V��
    lt_login_id         := FND_GLOBAL.LOGIN_ID;         -- �ŏI�X�V���O�C��
    lt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;  -- �v��ID
    lt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;     -- �A�v���P�[�V����ID
    lt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;  -- �v���O����ID
--
    -- �ꊇ�o�^
    FORALL ln_cnt IN 1..gt_doc_id_ins_tab.COUNT
      INSERT INTO xxcmn_txn_lot_cost(     -- ����ʃ��b�g�ʌ���(�A�h�I��)
          doc_type
        , doc_id
        , item_id
        , item_code
        , lot_id
        , lot_num
        , trans_qty
        , unit_price
        , created_by
        , creation_date
        , last_updated_by
        , last_update_date
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
      )
      VALUES
      (
          gv_doc_type_prod                -- �����^�C�v
        , gt_doc_id_ins_tab(ln_cnt)       -- ����ID
        , gt_item_id_ins_tab(ln_cnt)      -- �i��ID
        , gt_item_code_ins_tab(ln_cnt)    -- �i�ڃR�[�h
        , gt_lot_id_ins_tab(ln_cnt)       -- ���b�gID
        , gt_lot_num_ins_tab(ln_cnt)      -- ���b�gNo
        , gt_trans_qty_ins_tab(ln_cnt)    -- �������
        , gt_unit_price_ins_tab(ln_cnt)   -- �P��
        , lt_user_id                      -- �쐬��
        , SYSDATE                         -- �쐬��
        , lt_user_id                      -- �ŏI�X�V��
        , SYSDATE                         -- �ŏI�X�V��
        , lt_login_id                     -- �ŏI�X�V���O�C��
        , lt_conc_request_id              -- �v��ID
        , lt_prog_appl_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , lt_conc_program_id              -- �R���J�����g�E�v���O����ID
        , SYSDATE                         -- �v���O�����X�V��
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_table_batch;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : �f�[�^�_���v�擾����
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxcmn_txn_lot_cost IN  data_dump_rtype,  -- �f�[�^�_���v�p���R�[�h
    ov_dump               OUT NOCOPY VARCHAR2,  -- �f�[�^�_���v������
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�쐬
    -- ===============================
    ov_dump :=  TO_CHAR(ir_xxcmn_txn_lot_cost.batch_id)                             -- ����ID
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_date, 'YYYY/MM/DD HH24:MI:SS')  -- �����
                || gv_msg_comma ||  
                TO_CHAR(ir_xxcmn_txn_lot_cost.item_id)                              -- �i��ID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.item_code                                     -- �i�ڃR�[�h
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.lot_id)                               -- ���b�gID
                || gv_msg_comma ||
                ir_xxcmn_txn_lot_cost.lot_num                                       -- ���b�gNO
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.trans_qty)                            -- �������
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_txn_lot_cost.unit_price)                           -- �P��
                ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : put_success_dump
   * Description      : �����f�[�^�_���v�o�͏���
   ***********************************************************************************/
  PROCEDURE put_success_dump(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_success_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
    lv_dump VARCHAR2(5000);  -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    ins_data_rec  data_dump_rtype; -- �f�[�^�_���v�p���R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- ���W���[�������́FXXCMN ����
                ,gv_msg_xxcmn00005      -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    << success_dump_set_loop >>
    FOR ln_rec_cnt IN 1..gt_doc_id_ins_tab.COUNT LOOP
--
      -- =============================
      -- �_���v�p���R�[�h�ɃZ�b�g
      -- =============================
      ins_data_rec.batch_id   := gt_doc_id_ins_tab(ln_rec_cnt);      -- ����ID
      ins_data_rec.trans_date := gt_trans_date_ins_tab(ln_rec_cnt);  -- �����
      ins_data_rec.item_id    := gt_item_id_ins_tab(ln_rec_cnt);     -- �i��ID
      ins_data_rec.item_code  := gt_item_code_ins_tab(ln_rec_cnt);   -- �i�ڃR�[�h
      ins_data_rec.lot_id     := gt_lot_id_ins_tab(ln_rec_cnt);      -- ���b�gID
      ins_data_rec.lot_num    := gt_lot_num_ins_tab(ln_rec_cnt);     -- ���b�gNo
      ins_data_rec.trans_qty  := gt_trans_qty_ins_tab(ln_rec_cnt);   -- ����
      ins_data_rec.unit_price := gt_unit_price_ins_tab(ln_rec_cnt);  -- �P��
--
      -- =============================
      -- �f�[�^�_���v�擾����
      -- =============================
      get_data_dump(
          ir_xxcmn_txn_lot_cost => ins_data_rec
        , ov_dump               => lv_dump
        , ov_errbuf             => lv_errbuf
        , ov_retcode            => lv_retcode
        , ov_errmsg             => lv_errmsg
      );
      -- �f�[�^�_���v�擾�������G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- �����f�[�^���o��
      -- =============================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_set_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_success_dump;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT NOCOPY  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �����i�f�[�^���o
    CURSOR half_finished_goods_cur
    IS
      SELECT  itp.doc_id          doc_id                  -- ����ID
            , itp.trans_date      trans_date              -- �����
            , ximv.item_id        item_id                 -- �i��ID
            , ximv.item_no        item_no                 -- �i�ڃR�[�h
            , ilm.lot_id          lot_id                  -- ���b�gID
            , ilm.lot_no          lot_no                  -- ���b�gNO
            , SUM(itp.trans_qty)  trans_qty               -- �������
      FROM    ic_tran_pnd         itp                     -- �ۗ��݌Ƀg�����U�N�V����
            , xxcmn_item_mst_v    ximv                    -- OPM�i�ڏ��View
            , ic_lots_mst         ilm                     -- OPM���b�g�}�X�^
      WHERE itp.doc_type          =   gv_doc_type_prod    -- �����^�C�v�F���Y
      AND   itp.completed_ind     =   gn_completion       -- �����敪�F����
      AND   itp.line_type         =   gn_l_type_finished  -- ���׃^�C�v�F�����i
      AND   itp.trans_date        >=  gd_opening_date     -- �����
      AND   itp.reverse_id        IS NULL
      AND   itp.item_id           =   ximv.item_id        -- �i��ID
      AND   ximv.cost_manage_code =   gv_real_cost_price  -- �����Ǘ��敪�F0(���ی���)
      AND   itp.item_id           =   ilm.item_id         -- �i��ID
      AND   itp.lot_id            =   ilm.lot_id          -- ���b�gID
      GROUP BY
          itp.doc_id                                      -- ����ID
        , itp.trans_date                                  -- �����
        , ximv.item_id                                    -- �i��ID
        , ximv.item_no                                    -- �i�ڃR�[�h
        , ilm.lot_id                                      -- ���b�gID
        , ilm.lot_no                                      -- ���b�gNO
    ;
--
  -- ���Y���P���擾
  CURSOR by_product_price_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
    SELECT  ccd.cmpnt_cost        cmpnt_cost              -- �R���|�[�l���g����
    FROM    ic_tran_pnd           itp                     -- �ۗ��݌Ƀg�����U�N�V����
          ,(SELECT cc.calendar_code          calendar_code
                  ,cc.item_id                item_id
                  ,NVL(SUM(cc.cmpnt_cost),0) cmpnt_cost
            FROM  cm_cmpt_dtl cc
            WHERE cc.whse_code =   gt_whse_code
            GROUP BY calendar_code,item_id ) ccd          -- �W�������}�X�^
          , cm_cldr_hdr_b         clh                     -- �����J�����_�w�b�_
          , cm_cldr_dtl           cll                     -- �����J�����_����
    WHERE   itp.doc_type          =   gv_doc_type_prod    -- �����^�C�v�F���Y
    AND     itp.doc_id            =   batch_id            -- �o�b�`ID
    AND     itp.completed_ind     =   gn_completion       -- �����敪�F����
    AND     itp.line_type         =   gn_l_type_product   -- ���׃^�C�v�F���Y��
    AND     itp.reverse_id        IS NULL
    AND     itp.item_id           =   ccd.item_id         -- �i��ID
    AND     ccd.calendar_code     =   clh.calendar_code   -- �����J�����_�[�R�[�h
    AND     clh.calendar_code     =   cll.calendar_code   -- �����J�����_�[�R�[�h
    AND     itp.trans_date        >=  cll.start_date      -- ���ԁi���j
    AND     itp.trans_date        <=  cll.end_date        -- ���ԁi���j
  ;
--
  -- ���Y��������ʎ擾
  CURSOR by_product_qty_cur(batch_id ic_tran_pnd.doc_id%TYPE) IS
    SELECT  itp.trans_qty         trans_qty
    FROM    ic_tran_pnd           itp                     -- �ۗ��݌Ƀg�����U�N�V����
          , xxcmn_item_mst_v      ximv                    -- OPM�i�ڏ��View
    WHERE   itp.doc_type          = gv_doc_type_prod      -- �����^�C�v�F���Y
    AND     itp.doc_id            = batch_id              -- �o�b�`ID
    AND     itp.completed_ind     = gn_completion         -- �����敪�F����
    AND     itp.line_type         = gn_l_type_product     -- ���׃^�C�v�F���Y��
    AND     itp.reverse_id        IS NULL
    AND     itp.item_id           = ximv.item_id          -- �i��ID
  ;
--
    -- <�J�[�\����>���R�[�h�^
    half_finished_goods_cur_rec   half_finished_goods_cur%ROWTYPE;  -- �����i�f�[�^
    by_product_price_cur_rec      by_product_price_cur%ROWTYPE;     -- ���Y���P��
    by_product_qty_cur_rec        by_product_qty_cur%ROWTYPE;       -- ���Y���������
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_normal_cnt := 0;
--
    -- �o�^�pPL/SQL�\������
    gt_trans_date_ins_tab.DELETE; -- �����^�C�v
    gt_doc_id_ins_tab.DELETE;     -- ����ID
    gt_item_id_ins_tab.DELETE;    -- �i��ID
    gt_item_code_ins_tab.DELETE;  -- �i�ڃR�[�h
    gt_lot_id_ins_tab.DELETE;     -- ���b�gID
    gt_lot_num_ins_tab.DELETE;    -- ���b�gNo
    gt_trans_qty_ins_tab.DELETE;  -- �������
    gt_unit_price_ins_tab.DELETE; -- �P��
--
    -- =======================================
    -- B-1.�݌ɃI�[�v�����Ԏ擾����
    -- =======================================
    get_opening_period(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �G���[�̏ꍇ�͏I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �f�[�^���݊m�F
    OPEN half_finished_goods_cur;
    FETCH half_finished_goods_cur INTO half_finished_goods_cur_rec;
    IF (half_finished_goods_cur%NOTFOUND) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN ����
                   ,gv_msg_xxcmn10036   -- ���b�Z�[�W�FAPP-XXCMN-10036 �f�[�^�擾�G���[
                   ),1,5000);
      RAISE global_process_expt;
    END IF;
    CLOSE half_finished_goods_cur;
--
    -- =======================================
    -- B-2.�����i�f�[�^���o����
    -- =======================================
    <<get_half_finish_loop>>
    FOR loop_cnt IN half_finished_goods_cur LOOP
--
      -- �ϐ�������
      by_product_price_cur_rec.cmpnt_cost := NULL;  -- ���Y���P��
      by_product_qty_cur_rec.trans_qty    := NULL;  -- ���Y���������
--
      -- �f�[�^�J�E���g
      gn_index_cnt :=  gn_index_cnt + 1;  -- �f�[�^�J�E���g
--
      --=================================
      -- B-3.���Y���f�[�^���o����
      --=================================
      -- ���Y���P���擾
      OPEN by_product_price_cur(loop_cnt.doc_id);
      FETCH by_product_price_cur INTO by_product_price_cur_rec;
      CLOSE by_product_price_cur;
--
      -- ���Y��������ʎ擾
      OPEN by_product_qty_cur(loop_cnt.doc_id);
      FETCH by_product_qty_cur INTO by_product_qty_cur_rec;
      CLOSE by_product_qty_cur;
--
      --=================================
      -- B-4.�����i�f�[�^�i�[����
      --=================================
      gt_half_finish_goods_tab(gn_index_cnt).batch_id   :=  loop_cnt.doc_id;      -- �o�b�`ID
      gt_half_finish_goods_tab(gn_index_cnt).trans_date :=  loop_cnt.trans_date;  -- �����
      gt_half_finish_goods_tab(gn_index_cnt).item_id    :=  loop_cnt.item_id;     -- �i��ID
      gt_half_finish_goods_tab(gn_index_cnt).item_no    :=  loop_cnt.item_no;     -- �i�ڃR�[�h
      gt_half_finish_goods_tab(gn_index_cnt).lot_id     :=  loop_cnt.lot_id;      -- ���b�gID
      gt_half_finish_goods_tab(gn_index_cnt).lot_no     :=  loop_cnt.lot_no;      -- ���b�gNO
      gt_half_finish_goods_tab(gn_index_cnt).trans_qty  :=  loop_cnt.trans_qty;   -- �������
      -- ���Y���P��
      IF (by_product_price_cur_rec.cmpnt_cost IS NOT NULL) THEN
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_price := by_product_price_cur_rec.cmpnt_cost;
      ELSE
        -- �f�[�^���擾�ł��Ȃ��ꍇ��0���Z�b�g
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_price := 0;
      END IF;
      -- ���Y���������
      IF (by_product_qty_cur_rec.trans_qty IS NOT NULL) THEN
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_qty := by_product_qty_cur_rec.trans_qty;
      ELSE
        -- �f�[�^���擾�ł��Ȃ��ꍇ��0���Z�b�g
        gt_half_finish_goods_tab(gn_index_cnt).by_prod_qty := 0;
      END IF;
      gt_half_finish_goods_tab(gn_index_cnt).half_fin_price  := NULL;          -- �����i�P��
--
      --=================================
      -- B-5.�����i�f�[�^���o����
      --=================================
      get_row_materials(
          in_batch_id       =>  loop_cnt.doc_id   -- �o�b�`ID
        , ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ�͏����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      --=================================
      -- B-7.�����i�P���m�菈��
      --=================================
      set_decition_unit_price(
          in_index_cnt      =>  gn_index_cnt
        , ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �G���[�̏ꍇ�͏����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP get_half_finish_loop;
--
    --=================================
    -- B-8.�����i�P���m�菈��
    --=================================
    get_inject_prod_unit_price(
          ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    -- �G���[�̏ꍇ�͏����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --=================================
    -- B-9.�����i�f�[�^�o�^����
    --=================================
    ins_table_batch(
          ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    -- �G���[�̏ꍇ�͏����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --=================================
    -- �����f�[�^�_���v�o�͏���
    --=================================
    put_success_dump(
          ov_errbuf         =>  lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode        =>  lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg         =>  lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    -- �G���[�̏ꍇ�͏����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (half_finished_goods_cur%ISOPEN) THEN
        CLOSE half_finished_goods_cur;
      END IF;
      IF (by_product_price_cur%ISOPEN) THEN
        CLOSE by_product_price_cur;
      END IF;
      IF (by_product_qty_cur%ISOPEN) THEN
        CLOSE by_product_qty_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf    OUT NOCOPY  VARCHAR2,   --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode   OUT NOCOPY  VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn790002c;
/
