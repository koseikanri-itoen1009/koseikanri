CREATE OR REPLACE
PACKAGE BODY xxinv550004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550004c(body)
 * Description      : �I���X�i�b�v�V���b�g�쐬
 * MD.050           : �݌�(���[)               T_MD050_BPO_550
 * MD.070           : �I���X�i�b�v�V���b�g�쐬 T_MD070_BPO_55D
 * Version          : 1.12
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_snapshot      �I���X�i�b�v�V���b�g�쐬�t�@���N�V����
 *  add_del_info         �폜�Ώ۔z��Z�b�g�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0   R.Matusita       �V�K�쐬
 *  2008/05/07    1.1   S.Nakamura       �����ύX�v��#47,#62
 *  2008/05/20    1.2   K.Kumamoto       �����e�X�g��Q(User-Defined Exception)�Ή�
 *  2008/06/23    1.3   K.Kumamoto       �V�X�e���e�X�g��Q#260(�󕥎c�����X�g���I�����Ȃ�)�Ή�
 *  2008/08/28    1.4   Oracle �R�� ��_ PT 2_1_12 #33,T_S_503�Ή�
 *  2008/09/16    1.5   Y.Yamamoto       PT 2-1_12 #63
 *  2008/09/24    1.6   Y.Kawano         T_S_500�Ή�
 *  2008/10/02    1.7   Y.Yamamoto       PT 2-1_12 #85
 *  2008/11/11    1.8   Y.Kawano         �����e�X�g�w�E#565�Ή�
 *  2008/12/12    1.9   Y.Yamamoto       �{��#674�Ή�
 *  2009/03/30    1.10  H.Iida           �{�ԏ�Q#1346�Ή��i�c�ƒP�ʑΉ��j
 *  2009/09/10    1.11  M.Nomura         �{�ԏ�Q#1607�Ή�
 *  2010/05/13    1.12  M.Hokkanji       �{�ғ���Q#2250�Ή�
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
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
-- �莝���ʏ����i�[����e�[�u���^�̒�`
  TYPE  invent_monthly_stock_id   IS TABLE OF  NUMBER               INDEX BY BINARY_INTEGER;  -- �I�������݌�ID
  TYPE  whse_code_type   IS TABLE OF  ic_loct_inv.whse_code%TYPE    INDEX BY BINARY_INTEGER;  -- OPM�莝����  �q�ɃR�[�h
  TYPE  item_id_type     IS TABLE OF  ic_item_mst_b.item_id%TYPE    INDEX BY BINARY_INTEGER;  -- OPM�i�ڃ}�X�^  �i��ID
  TYPE  item_no_type     IS TABLE OF  ic_item_mst_b.item_no%TYPE    INDEX BY BINARY_INTEGER;  -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
  TYPE  lot_id_type      IS TABLE OF  ic_lots_mst.lot_id%TYPE       INDEX BY BINARY_INTEGER;  -- OPM���b�g�}�X�^  ���b�gID
  TYPE  lot_no_type      IS TABLE OF  ic_lots_mst.lot_no%TYPE       INDEX BY BINARY_INTEGER;  -- OPM���b�g�}�X�^  ���b�gNo
  TYPE  lot_ctl_type     IS TABLE OF  ic_item_mst_b.lot_ctl%TYPE    INDEX BY BINARY_INTEGER;  -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
  TYPE  loct_onhand_type IS TABLE OF  ic_loct_inv.loct_onhand%TYPE  INDEX BY BINARY_INTEGER;  -- OPM�莝����  �莝����
--
--add start 1.3
  TYPE  rec_del_info IS RECORD(
    whse_code  xxinv_stc_inventory_month_stck.whse_code%TYPE
   ,item_id    xxinv_stc_inventory_month_stck.item_id%TYPE
   ,invent_ym  xxinv_stc_inventory_month_stck.invent_ym%TYPE
  );
  TYPE tbl_del_info IS TABLE OF rec_del_info INDEX BY BINARY_INTEGER;
--add end 1.3
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  curr_invent_monthly_stock_id invent_monthly_stock_id; -- �I�������݌�ID
  curr_whse_code_tbl      whse_code_type;             -- OPM�莝����  �q�ɃR�[�h
  curr_item_id_tbl        item_id_type;               -- OPM�i�ڃ}�X�^  �i��ID
  curr_item_no_tbl        item_no_type;               -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
  curr_lot_id_tbl         lot_id_type;                -- OPM���b�g�}�X�^  ���b�gID
  curr_lot_no_tbl         lot_no_type;                -- OPM���b�g�}�X�^  ���b�gNo
  curr_lot_ctl_tbl        lot_ctl_type;               -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
  curr_loct_onhand_tbl    loct_onhand_type;           -- OPM�莝����  �莝����
--
  -- �O���p
  pre_invent_monthly_stock_id invent_monthly_stock_id; -- �I�������݌�ID
  pre_whse_code_tbl      whse_code_type;             -- OPM�莝����  �q�ɃR�[�h
  pre_item_id_tbl        item_id_type;               -- OPM�i�ڃ}�X�^  �i��ID
  pre_item_no_tbl        item_no_type;               -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
  pre_lot_id_tbl         lot_id_type;                -- OPM���b�g�}�X�^  ���b�gID
  pre_lot_no_tbl         lot_no_type;                -- OPM���b�g�}�X�^  ���b�gNo
  pre_lot_ctl_tbl        lot_ctl_type;               -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
  pre_loct_onhand_tbl    loct_onhand_type;           -- OPM�莝����  �莝����
--
  i                  NUMBER;                     -- ���[�v�J�E���^�[
--add start 1.3
  n                  NUMBER;
--add end 1.3
--
--add start 1.3
  del_info           tbl_del_info;               -- �폜���
--add end 1.3
  gn_ret_nomal       CONSTANT NUMBER :=  0;      -- ����
  gn_ret_error       CONSTANT NUMBER :=  1;      -- ���������G���[,���t�`�F�b�N�G���[
  gn_ret_lock_error  CONSTANT NUMBER :=  2;      -- ���b�N�G���[
  gn_ret_other_error CONSTANT NUMBER := -1;      -- ���̑��̃G���[
--
  gv_pkg_name        CONSTANT VARCHAR2(100) := 'xxinv550004c'; -- �p�b�P�[�W��
--
  lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
  lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
  lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
  -------------------------------------------------------------------------------------------------
  -- �uD-2. �莝���ʏ��v�\����
  -------------------------------------------------------------------------------------------------
  TYPE D_2_rec IS RECORD(
    whse_code   xxcmn_item_locations_v.whse_code%TYPE, -- OPM�莝����  �q�ɃR�[�h (��D-6�ƈႤ)
    item_id     xxcmn_item_mst_v.item_id%TYPE,         -- OPM�i�ڃ}�X�^  �i��ID
    item_no     xxcmn_item_mst_v.item_no%TYPE,         -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
    lot_id      ic_lots_mst.lot_id%TYPE,               -- OPM���b�g�}�X�^  ���b�gID
    lot_no      ic_lots_mst.lot_no%TYPE,               -- OPM���b�g�}�X�^  ���b�gNo
    lot_ctl     xxcmn_item_mst_v.lot_ctl%TYPE,         -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
    loct_onhand NUMBER);                               -- OPM�莝����  �莝����
  --���R�[�h�^����
  TYPE D_2_tab IS TABLE OF D_2_rec;
   lr_curr_cargo_rec D_2_tab;
--
  -------------------------------------------------------------------------------------------------
  -- �uD-6. �莝���ʏ��i�O�����j�v�\����
  -------------------------------------------------------------------------------------------------
  TYPE D_6_rec IS RECORD(
    whse_code   xxcmn_item_locations_v.whse_code%TYPE, -- OPM�莝����  �q�ɃR�[�h (��D-6�ƈႤ)
    item_id     xxcmn_item_mst_v.item_id%TYPE,         -- OPM�i�ڃ}�X�^  �i��ID
    item_no     xxcmn_item_mst_v.item_no%TYPE,         -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
    lot_id      ic_lots_mst.lot_id%TYPE,               -- OPM���b�g�}�X�^  ���b�gID
    lot_no      ic_lots_mst.lot_no%TYPE,               -- OPM���b�g�}�X�^  ���b�gNo
    lot_ctl     xxcmn_item_mst_v.lot_ctl%TYPE,         -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
    loct_onhand NUMBER);                               -- OPM�莝����  �莝����
  --���R�[�h�^����
  TYPE D_6_tab IS TABLE OF D_6_rec;
   lr_pre_cargo_rec D_6_tab;
--
  -- *** �O���[�o���E�J�[�\�� ***
  TYPE cursor_D2rec IS REF CURSOR;--�I���f�[�^�C���^�[�t�F�[�X�e�[�u���̑Ώۃf�[�^�擾�p
  TYPE cursor_D6rec IS REF CURSOR;--�I���f�[�^�C���^�[�t�F�[�X�e�[�u���̑Ώۃf�[�^�擾�p
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
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
  -- *** �폜�E�o�^�G���[�n���h�� ***
  global_del_ins_expt       EXCEPTION;
--
--################################  �Œ蕔 END   ##################################
--
--add start 1.3
  PROCEDURE add_del_info(
    iv_whse_code  IN VARCHAR2
   ,in_item_id    IN VARCHAR2
   ,iv_invent_ym  IN VARCHAR2
  )
  IS
    n      NUMBER;
    lb_add BOOLEAN;
  BEGIN
    n := del_info.first;
--
    --�z���1���ȏ㑶�݂���ꍇ
    IF del_info.EXISTS(n) THEN
      WHILE n IS NOT NULL LOOP
        IF (del_info(n).whse_code = iv_whse_code AND
            del_info(n).item_id   = in_item_id   AND
            del_info(n).invent_ym = iv_invent_ym) THEN
          lb_add := FALSE;
          EXIT;
        END IF;
        n := del_info.next(n);
      END LOOP;
      --�z��̒��Ɉ�v�����񂪑��݂��Ȃ��ꍇ
      lb_add := TRUE;
      n := del_info.last + 1; --�Y����=�ŏI�s+1
--
    --�z���1�������݂��Ȃ��ꍇ
    ELSE
      lb_add := TRUE;
      n := 1; --�Y����=1
    END IF;
--
    IF (lb_add) THEN
      del_info(n).whse_code := iv_whse_code;
      del_info(n).item_id   := in_item_id;
      del_info(n).invent_ym := iv_invent_ym;
    END IF;
--
  END add_del_info;
--add end 1.3
   /**********************************************************************************
   * Function Name    : create_snapshot
   * Description      : �I���X�i�b�v�V���b�g�쐬�֐�
   ***********************************************************************************/
  FUNCTION create_snapshot(
    iv_invent_ym        IN  VARCHAR2,               -- �Ώ۔N��(YYYYMM)
    iv_whse_code1       IN  VARCHAR2 DEFAULT NULL,  -- �q�ɃR�[�h�P
    iv_whse_code2       IN  VARCHAR2 DEFAULT NULL,  -- �q�ɃR�[�h�Q
    iv_whse_code3       IN  VARCHAR2 DEFAULT NULL,  -- �q�ɃR�[�h�R
    iv_whse_department1 IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������P
    iv_whse_department2 IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������Q
    iv_whse_department3 IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������R
    iv_block1           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�P
    iv_block2           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�Q
    iv_block3           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�R
    iv_arti_div_code    IN  VARCHAR2,               -- ���i�敪
    iv_item_class_code  IN  VARCHAR2)               -- �i�ڋ敪
    RETURN NUMBER
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_snapshot'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
    -- *** ���[�J���萔 ***
    cv_prf_org_id CONSTANT VARCHAR2(100) := 'ORG_ID';          -- �v���t�@�C���FORG_ID
-- 2009/03/30 H.Iida ADD END
--
    -- *** ���[�J���ϐ� ***
--    
    lv_pre_invent_ym           VARCHAR2(6);-- �N���p�����[�^�̑Ώ۔N���̑O��
    ld_invent_begin_ymd        DATE;       -- ������
    ld_invent_end_ymd          DATE;       -- ������
    ld_pre_invent_begin_ymd    DATE;       -- �O���̌�����
    ld_pre_invent_end_ymd      DATE;       -- �O���̌�����
--
    ln_whse_code_nullflg       NUMBER;     -- �q�ɃR�[�hNULL�`�F�b�N�t���O
    ln_whse_department_nullflg NUMBER;     -- �q�ɊǗ�����NULL�`�F�b�N�t���O
    ln_block_nullflg           NUMBER;     -- �u���b�NNULL�`�F�b�N�t���O
--
    TYPE ary_quantity IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;-- ���ʔz��
--
    ln_d3_itp_trans_qty ary_quantity;      -- D-3 OPM�ۗ��݌Ƀg�����U�N�V���� ����
    ln_d3_itc_trans_qty ary_quantity;      -- D-3 OPM�����݌Ƀg�����U�N�V���� ����
    ln_d4_quantity ary_quantity;           -- D-4. �ړ��ϑ�����񒊏o ����
    ln_d5_quantity ary_quantity;           -- D-5. �o�ׁE�L���ϑ�����񒊏o ����
    ln_d7_quantity ary_quantity;           -- D-7. �ړ��ϑ�����񒊏o�i�O�����j ����
    ln_d8_quantity ary_quantity;           -- D-8. �o�ׁE�L���ϑ�����񒊏o�i�O�����j ����
-- 2008/12/12 v1.9 Y.Yamamoto add start
    ln_d12_quantity ary_quantity;          -- D-12.�ړ��ϑ�����񒊏o ����
    ln_d13_quantity ary_quantity;          -- D-13.�o�ׁE�L���ϑ�����񒊏o ����
    ln_d14_quantity ary_quantity;          -- D-14.�ړ��ϑ�����񒊏o�i�O�����j ����
    ln_d15_quantity ary_quantity;          -- D-15.�o�ׁE�L���ϑ�����񒊏o�i�O�����j ����
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
    ln_user_id          NUMBER;            -- ���O�C�����Ă��郆�[�U�[
    ln_login_id         NUMBER;            -- �ŏI�X�V���O�C��
    ln_conc_request_id  NUMBER;            -- �v��ID
    ln_prog_appl_id     NUMBER;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id  NUMBER;            -- �R���J�����g�E�v���O����ID
--
    lv_item_div     VARCHAR2(100);         -- �v���t�@�C��'���i�敪'
    lv_article_div  VARCHAR2(100);         -- �v���t�@�C��'�i�ڋ敪'
    lv_orgid_div    NUMBER;                -- �v���t�@�C��'�}�X�^�g�DID'
--
    lv_item_cd      VARCHAR2(40);          -- �i�ڃ}�X�^�`���u�����p�i�ڃR�[�h
--
    ln_invent_monthly_stock_id NUMBER;     -- �I�������݌�ID
--
    lv_sysdate_ym   VARCHAR2(6);           -- ���ݓ��t
--
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
    lv_org_id       VARCHAR2(1000);        -- ORG_ID
-- 2009/03/30 H.Iida ADD END
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
    lv_D2sql            VARCHAR2(15000) DEFAULT NULL; -- ���ISQL������ D-2. �莝���ʏ��
    lv_D6sql            VARCHAR2(15000) DEFAULT NULL; -- ���ISQL������ D-6. �莝���ʏ��i�O�����j
    lv_where_whsecode   VARCHAR2(100)   DEFAULT NULL; -- ���ISQL������ ���̓p�����[�^�F�q�ɃR�[�h
    lv_where_block      VARCHAR2(100)   DEFAULT NULL; -- ���ISQL������ ���̓p�����[�^�F�u���b�N
    lv_where_department VARCHAR2(100)   DEFAULT NULL; -- ���ISQL������ ���̓p�����[�^�F�q�ɊǗ�����
    lv_loc_where        VARCHAR2(300)   DEFAULT NULL; -- ���ISQL������ ���̓p�����[�^
--
    lrec_D2data cursor_D2rec;  -- �I���f�[�^�C���^�t�F�[�X�J�[�\��
    lrec_D6data cursor_D6rec;  -- �I���f�[�^�C���^�t�F�[�X�J�[�\��
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
--
--add start 1.3
    TYPE refcursor IS REF CURSOR;
    cur_del refcursor;
--add end 1.3
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
    -- D-2. �莝���ʏ�񒊏o�J�[�\��
/*    CURSOR current_cargo_cur IS
    SELECT iiim.whse_code whse_code,               -- OPM�莝����  �q�ɃR�[�h (��D-6�ƈႤ)
           iiim.item_id   item_id,                 -- OPM�i�ڃ}�X�^  �i��ID
           iiim.item_no   item_no,                 -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
           iiim.lot_id    lot_id,                  -- OPM���b�g�}�X�^  ���b�gID
           iiim.lot_no    lot_no,                  -- OPM���b�g�}�X�^  ���b�gNo
           iiim.lot_ctl   lot_ctl,                 -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
           SUM(NVL(ili.loct_onhand,0)) loct_onhand -- OPM�莝����  �莝����
    FROM   ic_loct_inv ili,                        -- OPM�莝���� (��D-6�ƈႤ)
           (SELECT xilv.whse_code,
                   xilv.segment1,                  -- add 2008/05/07 #47�Ή�
                   ximv.item_id,
                   ximv.item_no, 
                   ilm.lot_id, 
                   ximv.lot_ctl,
                   ilm.lot_no
            FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                   ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                   xxcmn_item_locations_v xilv,   -- OPM�ۊǏꏊ���VIEW
                   xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                   xxcmn_item_categories_v xicv2  -- OPM�i�ڃJ�e�S���������VIEW2
                   --org_acct_periods oap         -- �݌ɉ�v����  -- del 2008/5/8 #47�Ή�
            WHERE  ximv.item_id = ilm.item_id     -- OPM�i�ڃ}�X�^.�i��ID   = OPM���b�g�}�X�^.�i��ID
            AND   (
                    (((0 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- �t���O��0�Ȃ�q�ɃR�[�h�P-�R���s��
                       AND (xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                    )
                  OR
                    (((1 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- �t���O��0�Ȃ�u���b�N�P-�R���s��
                       AND xilv.distribution_block IN (iv_block1, iv_block2, iv_block3)
                    )
                  OR
                    (((0 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- �q�ɃR�[�h�A�u���b�N�����w�肵���ꍇ
                       AND
                         (((xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                         OR
                         (xilv.distribution_block IN (iv_block1, iv_block2, iv_block3))))
                    )
                  OR 
                     ((1 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- �w�肵�Ȃ��ꍇ
                  )
            AND
                  (
                   ((0 = ln_whse_department_nullflg) -- �t���O��0�Ȃ�q�ɊǗ������P-�R���s��
                     AND (xilv.whse_department IN (iv_whse_department1, iv_whse_department2, iv_whse_department3)))
                   OR
                    (1 = ln_whse_department_nullflg)
                  )
            AND    xicv1.category_set_name = lv_item_div    -- ���i�敪
            AND    xicv1.segment1          = iv_arti_div_code
            AND    xicv1.item_id           = ximv.item_id
            AND    xicv2.item_id           = ximv.item_id
            AND    xicv2.category_set_name = lv_article_div -- �i�ڋ敪
            AND    xicv2.segment1          = iv_item_class_code
            -- AND    xilv.mtl_organization_id= oap.organization_id  -- #47�Ή�
           ) iiim
    WHERE  iiim.item_id            = ili.item_id(+)
    AND    iiim.whse_code          = ili.whse_code(+)
    AND    iiim.lot_id             = ili.lot_id(+)
    AND    iiim.segment1           = ili.location(+)   -- add 2008/05/07 #47�Ή�
    -- mod start 2008/05/07 #47�Ή�
    -- GROUP BY iiim.whse_code, iiim.item_no, iiim.lot_no, iiim.item_id, iiim.lot_id, iiim.lot_ctl,ili.loct_onhand;
    GROUP BY 
       iiim.whse_code
      ,iiim.item_id
      ,iiim.item_no
      ,iiim.lot_id
      ,iiim.lot_no
      ,iiim.lot_ctl
      ;*/
    -- mod end 2008/05/07 #47�Ή�
--
--
    -- D-6. �莝���ʏ�񒊏o�i�O�����j�J�[�\��
/*    CURSOR  pre_cargo_cur (ld_cur_pre_invent_begin_ymd DATE) IS
    SELECT iiim.whse_code whse_code,               -- OPM�莝����  �q�ɃR�[�h (��D-6�ƈႤ)
           iiim.item_id item_id,                   -- OPM�i�ڃ}�X�^  �i��ID
           iiim.item_no item_no,                   -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
           iiim.lot_id   lot_id,                   -- OPM���b�g�}�X�^  ���b�gID
           iiim.lot_no   lot_no,                   -- OPM���b�g�}�X�^  ���b�gNo
           iiim.lot_ctl lot_ctl,                   -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
           SUM(NVL(ipb.loct_onhand,0)) loct_onhand -- OPM���b�g�ʌ����݌�  �莝����
    FROM   ic_perd_bal ipb,                        -- OPM���b�g�ʌ����݌� (��D-2�ƈႤ)
           (SELECT xilv.whse_code,
                   xilv.segment1,                  -- add 2008/05/07 #47�Ή�
                   ximv.item_id,
                   ximv.item_no, 
                   ilm.lot_id, 
                   ximv.lot_ctl,
                   ilm.lot_no,
                   oap.period_year,
                   oap.period_num
            FROM   xxcmn_item_mst_v ximv,         -- OPM�i�ڃ}�X�^���VIEW
                   ic_lots_mst ilm,               -- OPM���b�g�}�X�^
                   xxcmn_item_locations_v xilv,   -- OPM�ۊǏꏊ���VIEW
                   xxcmn_item_categories_v xicv1, -- OPM�i�ڃJ�e�S���������VIEW1
                   xxcmn_item_categories_v xicv2, -- OPM�i�ڃJ�e�S���������VIEW2
                   org_acct_periods oap           -- �݌ɉ�v����
            WHERE  ximv.item_id = ilm.item_id     -- OPM�i�ڃ}�X�^.�i��ID   = OPM���b�g�}�X�^.�i��ID
            AND   (
                    (((0 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- �t���O��0�Ȃ�q�ɃR�[�h�P-�R���s��
                       AND (xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                    )
                  OR
                    (((1 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- �t���O��0�Ȃ�u���b�N�P-�R���s��
                       AND xilv.distribution_block IN (iv_block1, iv_block2, iv_block3)
                    )
                  OR
                    (((0 = ln_whse_code_nullflg) AND (0 = ln_block_nullflg))  -- �q�ɃR�[�h�A�u���b�N�����w�肵���ꍇ
                       AND
                         (((xilv.whse_code IN (iv_whse_code1, iv_whse_code2, iv_whse_code3))
                         OR
                         (xilv.distribution_block IN (iv_block1, iv_block2, iv_block3))))
                    )
                  OR 
                     ((1 = ln_whse_code_nullflg) AND (1 = ln_block_nullflg))  -- �w�肵�Ȃ��ꍇ
                  )
            AND
                  (
                   ((0 = ln_whse_department_nullflg) -- �t���O��0�Ȃ�q�ɊǗ������P-�R���s��
                     AND (xilv.whse_department IN (iv_whse_department1, iv_whse_department2, iv_whse_department3)))
                   OR
                    (1 = ln_whse_department_nullflg)
                  )
            AND    xicv1.category_set_name = lv_item_div    -- ���i�敪
            AND    xicv1.segment1          = iv_arti_div_code
            AND    xicv1.item_id           = ximv.item_id
            AND    xicv2.item_id           = ximv.item_id
            AND    xicv2.category_set_name = lv_article_div -- �i�ڋ敪
            AND    xicv2.segment1          = iv_item_class_code
            AND    oap.period_start_date   = ld_cur_pre_invent_begin_ymd -- OPM���b�g�ʌ����݌�.�݌Ɋ���= �N���p�����[�^�̑Ώ۔N���̑O��
            AND    xilv.mtl_organization_id= oap.organization_id
           ) iiim
    WHERE  iiim.item_id               = ipb.item_id(+)
    AND    iiim.whse_code             = ipb.whse_code(+)
    AND    iiim.lot_id                = ipb.lot_id(+)
    -- AND    iiim.period_year           = TO_NUMBER(ipb.fiscal_year(+)) -- mod 2008/05/07 #62�Ή�
    AND    to_char(iiim.period_year)  = ipb.fiscal_year(+)               -- mod 2008/05/07 #62�Ή�
    AND    iiim.period_num            = ipb.period(+)
    AND    iiim.segment1              = ipb.location(+)                  -- add 2008/05/07 #47�Ή�
    --mod start 2008/05/07 #47�Ή�
    -- GROUP BY iiim.whse_code, iiim.item_no, iiim.lot_no, iiim.item_id, iiim.lot_id, iiim.lot_ctl,ipb.loct_onhand;--#47�Ή�
    GROUP BY 
      iiim.whse_code
     ,iiim.item_id
     ,iiim.item_no
     ,iiim.lot_id
     ,iiim.lot_no
     ,iiim.lot_ctl
     ;*/
    --mod end 2008/05/07 #47�Ή�
--
    -- *** ���[�J���E���R�[�h ***
--    lr_curr_cargo_rec   current_cargo_cur%ROWTYPE;
--    lr_pre_cargo_rec    pre_cargo_cur%ROWTYPE;
-- 2008/09/16 v1.5 Y.Yamamoto Delete End

  BEGIN
--
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
    --==========================
    -- ORG_ID�擾
    --==========================
    lv_org_id := FND_PROFILE.VALUE(cv_prf_org_id);
-- 2009/03/30 H.Iida ADD END
--
--add start 2008/05/12 #47�Ή�
    curr_invent_monthly_stock_id.delete;   -- �I�������݌�ID
    curr_whse_code_tbl.delete;             -- OPM�莝����  �q�ɃR�[�h
    curr_item_id_tbl.delete;               -- OPM�i�ڃ}�X�^  �i��ID
    curr_item_no_tbl.delete;               -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
    curr_lot_id_tbl.delete;                -- OPM���b�g�}�X�^  ���b�gID
    curr_lot_no_tbl.delete;                -- OPM���b�g�}�X�^  ���b�gNo
    curr_lot_ctl_tbl.delete;               -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
    curr_loct_onhand_tbl.delete;           -- OPM�莝����  �莝����
    pre_invent_monthly_stock_id.delete;    -- �I�������݌�ID
    pre_whse_code_tbl.delete;              -- OPM�莝����  �q�ɃR�[�h
    pre_item_id_tbl.delete;                -- OPM�i�ڃ}�X�^  �i��ID
    pre_item_no_tbl.delete;                -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
    pre_lot_id_tbl.delete;                 -- OPM���b�g�}�X�^  ���b�gID
    pre_lot_no_tbl.delete;                 -- OPM���b�g�}�X�^  ���b�gNo
    pre_lot_ctl_tbl.delete;                -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
    pre_loct_onhand_tbl.delete;            -- OPM�莝����  �莝����
--add end 2008/05/12 #47�Ή�
--add start 1.3
    del_info.delete;                       -- �폜���
--add end 1.3
--
    lv_sysdate_ym := TO_CHAR(SYSDATE,'YYYYMM');
--
    -- ���ʍX�V���̎擾
    ln_user_id         := FND_GLOBAL.USER_ID;         -- ���O�C�����Ă��郆�[�U�[��ID�擾
    ln_login_id        := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    ln_conc_request_id := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    ln_prog_appl_id    := FND_GLOBAL.PROG_APPL_ID;    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���l�̎擾 (���i�敪)
    lv_item_div := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_item_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- �v���t�@�C���l�̎擾 (�i�ڋ敪)
    lv_article_div := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_article_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- �v���t�@�C���l�̎擾 (�}�X�^�g�DID)
    lv_orgid_div := FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID');
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_orgid_div IS NULL) THEN
      RETURN gn_ret_other_error;
    END IF;
--
    -- D-1.��������
    -- �K�{���̓p�����[�^�A���t�^�`�F�b�N
    IF ((iv_invent_ym IS NULL) OR (iv_arti_div_code IS NULL) OR (iv_item_class_code IS NULL)) THEN 
      -- �Ώ۔N���A���i�敪�A�i�ڋ敪���w�肳��ĂȂ��ꍇ�A�G���[��Ԃ�
      RETURN gn_ret_error;
    ELSIF (gn_ret_error = xxcmn_common_pkg.check_param_date_yyyymm(iv_invent_ym)) THEN
      -- �Ώ۔N����YYYYMM�łȂ��ꍇ�A�G���[��Ԃ�
      RETURN gn_ret_error;
    END IF;
--
    -- �N���p�����[�^�̑Ώ۔N���̑O�����擾
    lv_pre_invent_ym := TO_CHAR(ADD_MONTHS(FND_DATE.STRING_TO_DATE(iv_invent_ym,'YYYY/MM'),-1),'YYYYMM');
--
    -- �p�����[�^�q�ɃR�[�hNULL�`�F�b�N
    IF  (iv_whse_code1 IS NULL)
    AND (iv_whse_code2 IS NULL)
    AND (iv_whse_code3 IS NULL) THEN
      -- �q�ɃR�[�h�P�`�R�����ׂ�NULL�̏ꍇ
      ln_whse_code_nullflg := 1;
    ELSE
      ln_whse_code_nullflg := 0;
    END IF;
--
    -- �p�����[�^�q�ɊǗ�����NULL�`�F�b�N
    IF  (iv_whse_department1 IS NULL)
    AND (iv_whse_department2 IS NULL)
    AND (iv_whse_department3 IS NULL) THEN
      -- �q�ɊǗ������P�`�R�����ׂ�NULL�̏ꍇ
      ln_whse_department_nullflg := 1;
    ELSE
      ln_whse_department_nullflg := 0;
    END IF;
--
    -- �p�����[�^�u���b�NNULL�`�F�b�N
    IF  (iv_block1 IS NULL)
    AND (iv_block2 IS NULL)
    AND (iv_block3 IS NULL) THEN
      -- �u���b�N�P�`�R�����ׂ�NULL�̏ꍇ
      ln_block_nullflg := 1;
    ELSE
      ln_block_nullflg := 0;
    END IF;
--
    ld_invent_begin_ymd := FND_DATE.STRING_TO_DATE(iv_invent_ym || '01','YYYY/MM/DD'); -- �������̎擾
    ld_invent_end_ymd   := ADD_MONTHS(ld_invent_begin_ymd,1) - 1;                      -- �������̎擾
--
    ld_pre_invent_begin_ymd := FND_DATE.STRING_TO_DATE(lv_pre_invent_ym || '01','YYYY/MM/DD'); -- �O���̌������̎擾
    ld_pre_invent_end_ymd   := ADD_MONTHS(ld_pre_invent_begin_ymd,1) - 1;                      -- �O���̌������̎擾
--
    -- �������n�܂�
    -- �莝���ʏ�񂪎擾�ł��Ă���ꍇ
    -- D-2�����s
--
-- 2008/09/16 v1.5 Y.Yamamoto ADD Start
    -- ���̓p�����[�^�F�q�ɃR�[�h�ҏW
    IF (iv_whse_code1 IS NOT NULL) AND
       (iv_whse_code2 IS NOT NULL) AND
       (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code2 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code2 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code1 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code IN (''' || iv_whse_code2 || ''', ''' || iv_whse_code3 || ''')';
    ELSIF (iv_whse_code1 IS NOT NULL) AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code1 || '''';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NOT NULL) AND
          (iv_whse_code3 IS NULL)     THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code2 || '''';
    ELSIF (iv_whse_code1 IS NULL)     AND
          (iv_whse_code2 IS NULL)     AND
          (iv_whse_code3 IS NOT NULL) THEN
      lv_where_whsecode :=
        'xilv.whse_code = ''' || iv_whse_code3 || '''';
    ELSE
      lv_where_whsecode := NULL;
    END IF;
--
    -- ���̓p�����[�^�F�u���b�N�ҏW
    IF    (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block2 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block2 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block1 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block IN (''' || iv_block2 || ''', ''' || iv_block3 || ''')';
    ELSIF (iv_block1 IS NOT NULL) AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block1 || '''';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NOT NULL) AND
          (iv_block3 IS NULL)     THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block2 || '''';
    ELSIF (iv_block1 IS NULL)     AND
          (iv_block2 IS NULL)     AND
          (iv_block3 IS NOT NULL) THEN
      lv_where_block :=
        'xilv.distribution_block = ''' || iv_block3 || '''';
    ELSE
      lv_where_block := NULL;
    END IF;
--
    -- ���̓p�����[�^�F�q�ɊǗ������ҏW
    IF    (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department2 || ''', ''' || iv_whse_department3 || ''')' ;
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department2 || ''')';
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department1 || ''', ''' || iv_whse_department3 || ''')';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department IN (''' || iv_whse_department2 || ''', ''' || iv_whse_department3 || ''')';
    ELSIF (iv_whse_department1 IS NOT NULL) AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department1 || '''';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NOT NULL) AND
          (iv_whse_department3 IS NULL)     THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department2 || '''';
    ELSIF (iv_whse_department1 IS NULL)     AND
          (iv_whse_department2 IS NULL)     AND
          (iv_whse_department3 IS NOT NULL) THEN
      lv_where_department :=
        'xilv.whse_department = ''' || iv_whse_department3 || '''';
    ELSE
      lv_where_department := NULL;
    END IF;
--
    -- �p�����[�^�ҏW
    IF    (ln_whse_code_nullflg = 0) AND
          (ln_block_nullflg     = 1) THEN   -- �q�ɃR�[�h���w�肵���ꍇ
      lv_loc_where := lv_where_whsecode;
    ELSIF (ln_whse_code_nullflg = 1) AND
          (ln_block_nullflg     = 0) THEN   -- �u���b�N���w�肵���ꍇ
      lv_loc_where := lv_where_block;
    ELSIF (ln_whse_code_nullflg = 0) AND
          (ln_block_nullflg     = 0) THEN   -- �q�ɃR�[�h�A�u���b�N�����w�肵���ꍇ
      lv_loc_where := lv_where_whsecode
        || '       OR '
        || lv_where_block;
    ELSE                                    -- �w�肵�Ȃ��ꍇ
      lv_loc_where := NULL;
    END IF;
--
    -- �q�ɊǗ������ҏW
    IF (ln_whse_department_nullflg = 0) THEN
      IF (lv_loc_where IS NOT NULL) THEN
        -- ���łɕҏW��
        lv_loc_where := lv_loc_where
          || '       AND '
          || lv_where_department;
      ELSE
        -- ���ҏW
        lv_loc_where := lv_where_department;
      END IF;
    END IF;
-- 2008/09/16 v1.5 Y.Yamamoto ADD End
--
    BEGIN
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
      --SQL�쐬�J�n
      lv_D2sql := 
           'SELECT xilv.whse_code              whse_code '   -- OPM�莝����  �q�ɃR�[�h (��D-6�ƈႤ)
        || '      ,iimb.item_id                item_id '     -- OPM�i�ڃ}�X�^  �i��ID
        || '      ,iimb.item_no                item_no '     -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
        || '      ,ilm.lot_id                  lot_id '      -- OPM���b�g�}�X�^  ���b�gID
        || '      ,ilm.lot_no                  lot_no '      -- OPM���b�g�}�X�^  ���b�gNo
        || '      ,iimb.lot_ctl                lot_ctl '     -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
        || '      ,SUM(NVL(ili.loct_onhand,0)) loct_onhand ' -- OPM�莝����  �莝����
        || 'FROM   ic_loct_inv              ili '            -- OPM�莝���� (��D-6�ƈႤ)
        || '      ,xxcmn_item_locations_v   xilv '           -- OPM�ۊǏꏊ���VIEW
        || '      ,ic_item_mst_b            iimb '           -- OPM�i�ڃ}�X�^
        || '      ,xxcmn_item_mst_b         ximb '           -- OPM�i�ڃA�h�I���}�X�^
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� start *----------*
        || '      ,ic_lots_mst              ilm '            -- OPM���b�g�}�X�^
        || '      ,xxinv_lots_notzero_mst_v xlmv '           -- �莝������b�gVIEW
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� end   *----------*
        || '      ,xxcmn_item_categories5_v xicv '           -- OPM�i�ڃJ�e�S���������VIEW1
        || 'WHERE xicv.prod_class_code    = :arti_div_code '
        || 'AND   xicv.item_class_code    = :item_class_code '
        || 'AND   iimb.item_id            = ximb.item_id '
        || 'AND   iimb.inactive_ind      <> ''1'' '
        || 'AND   ximb.obsolete_class    <> ''1'' '
        || 'AND   ximb.start_date_active <= TRUNC(SYSDATE) '
        || 'AND   ximb.end_date_active   >= TRUNC(SYSDATE) '
        || 'AND   iimb.item_id            = xicv.item_id '
        || 'AND   ilm.item_id             = iimb.item_id ';    -- OPM���b�g�}�X�^.�i��ID   = OPM�i�ڃ}�X�^.�i��ID
--
      -- SQL�{�̂ƃp�����[�^������
      IF (lv_loc_where IS NOT NULL) THEN
        -- �q�ɃR�[�h�A�u���b�N�A�q�ɊǗ��������w�肳�ꂽ
        lv_D2sql := lv_D2sql
          || 'AND '
          || lv_loc_where;
      END IF;
      -- �w�肳��Ȃ�������WHERE��͍쐬���Ȃ�
--
      lv_D2sql := lv_D2sql
        || 'AND   ili.item_id   = iimb.item_id '
        || 'AND   ili.lot_id    = ilm.lot_id '
        || 'AND   ili.whse_code = xilv.whse_code '
        || 'AND   ili.location  = xilv.segment1 '   -- add 2008/05/07 #47�Ή�
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� start *----------*
        || 'AND   ili.item_id   = xlmv.item_id '
        || 'AND   ili.lot_id    = xlmv.lot_id '
        || 'AND   ili.whse_code = xlmv.whse_code '
        || 'AND   ili.location  = xlmv.location '
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� end   *----------*
        || 'GROUP BY '
        || '      xilv.whse_code '
        || '     ,iimb.item_id '
        || '     ,iimb.item_no '
        || '     ,ilm.lot_id '
        || '     ,ilm.lot_no '
        || '     ,iimb.lot_ctl ';
--
--      OPEN current_cargo_cur;-- �J�[�\���I�[�v��
        OPEN  lrec_D2data FOR lv_D2sql
        USING iv_arti_div_code
             ,iv_item_class_code;
        FETCH lrec_D2data BULK COLLECT INTO lr_curr_cargo_rec;
        CLOSE lrec_D2data;
--
--        i := 0;
--        LOOP
          -- ���R�[�h�Ǎ�
--          FETCH current_cargo_cur INTO lr_curr_cargo_rec;
--          EXIT WHEN current_cargo_cur%NOTFOUND;
        <<D2_loop>>
        FOR i IN 1 .. lr_curr_cargo_rec.COUNT LOOP
--
--          i := i + 1;
-- 2008/09/16 v1.5 Y.Yamamoto Update End
          curr_whse_code_tbl(i)   := lr_curr_cargo_rec(i).whse_code;   -- OPM�莝����  �q�ɃR�[�h
          curr_item_id_tbl(i)     := lr_curr_cargo_rec(i).item_id;     -- OPM�i�ڃ}�X�^  �i��ID
          curr_item_no_tbl(i)     := lr_curr_cargo_rec(i).item_no;     -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
          curr_lot_id_tbl(i)      := lr_curr_cargo_rec(i).lot_id;      -- OPM���b�g�}�X�^  ���b�gID
          curr_lot_no_tbl(i)      := lr_curr_cargo_rec(i).lot_no;      -- OPM���b�g�}�X�^  ���b�gNo
          curr_lot_ctl_tbl(i)     := lr_curr_cargo_rec(i).lot_ctl;     -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
          curr_loct_onhand_tbl(i) := lr_curr_cargo_rec(i).loct_onhand; -- OPM�莝����  �莝����
--
--add start 1.3
          add_del_info(
            lr_curr_cargo_rec(i).whse_code
           ,lr_curr_cargo_rec(i).item_id
           ,iv_invent_ym
          );
--add end 1.3
          ln_d3_itp_trans_qty(i):=0;
          ln_d3_itc_trans_qty(i):=0;
          ln_d4_quantity(i):=0;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          ln_d12_quantity(i) := 0;
          ln_d13_quantity(i) := 0;
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
          -- ���ׂ��̊m�F
          IF (iv_invent_ym < lv_sysdate_ym) THEN
--
            BEGIN
              -- ���s�����Ώ۔N���̗����ȍ~�ł���ꍇ�AD-2. �莝���ʏ�񒊏o
              -- D-3.���������񒊏o����
              -- OPM�ۗ��݌Ƀg�����U�N�V����
              SELECT SUM(NVL(itp.trans_qty,0) * -1)                   -- ���ʁi���l�𔽓]������j
              INTO   ln_d3_itp_trans_qty(i)
              FROM   ic_tran_pnd itp                                  -- OPM�ۗ��݌Ƀg�����U�N�V����
              WHERE  itp.whse_code = curr_whse_code_tbl(i)            -- �q�ɃR�[�h
              AND    itp.item_id = curr_item_id_tbl(i)                -- �i��ID
-- Ver1.12 M.Hokkanji UPD START
--              AND    (0 = curr_lot_ctl_tbl(i)                         -- ���b�g�Ǘ��i�ڂ̏ꍇ(0:�Ȃ��A1:����)
--                      OR (itp.lot_id = curr_lot_id_tbl(i))            -- OPM�i�ڃ}�X�^  ���b�gID
--                     )
              AND    itp.lot_id  = curr_lot_id_tbl(i)
-- Ver1.12 M.Hokkanji UPD END
              --AND itp.trans_date > ld_invent_end_ymd                  -- ������̔N��
-- Ver1.12 M.Hokkanji UPD START
--              AND TRUNC(itp.trans_date) > TRUNC(ld_invent_end_ymd)      -- ������̔N��   -- 2008/05/07 mod
              AND itp.trans_date >= TRUNC(ADD_MONTHS(ld_invent_begin_ymd,1))      -- ������̔N��   -- 2008/05/07 mod
-- Ver1.12 M.Hokkanji UPD END
              AND itp.completed_ind = 1                               -- �����t���O
              GROUP BY itp.whse_code, itp.item_id, itp.lot_id;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d3_itp_trans_qty(i) := 0;
            END;
--
            BEGIN
              -- OPM�����݌Ƀg�����U�N�V����
              SELECT SUM(NVL(itc.trans_qty,0) * -1)                       -- ���ʁi���l�𔽓]������j
              INTO   ln_d3_itc_trans_qty(i)
              FROM   ic_tran_cmp itc                                  -- OPM�����݌Ƀg�����U�N�V����
              WHERE  itc.whse_code = curr_whse_code_tbl(i)            -- �q�ɃR�[�h
              AND    itc.item_id = curr_item_id_tbl(i)                -- �i��ID
-- Ver1.12 M.Hokkanji UPD START
--              AND    (0 = curr_lot_ctl_tbl(i)                         -- ���b�g�Ǘ��i�ڂ̏ꍇ(0:�Ȃ��A1:����)
--                       OR (itc.lot_id = curr_lot_id_tbl(i))           -- OPM�i�ڃ}�X�^  ���b�gID
--                     )
              AND    itc.lot_id = curr_lot_id_tbl(i)                  -- OPM�i�ڃ}�X�^  ���b�gID
-- Ver1.12 M.Hokkanji UPD END
              --AND itc.trans_date > ld_invent_end_ymd                  -- ������̔N��
-- Ver1.12 M.Hokkanji UPD START
--              AND TRUNC(itc.trans_date) > TRUNC(ld_invent_end_ymd)      -- ������̔N��    -- 2008/05/07 mod
              AND itc.trans_date >= TRUNC(ADD_MONTHS(ld_invent_begin_ymd,1))      -- ������̔N��    -- 2008/05/07 mod
-- Ver1.12 M.Hokkanji UPD END
              GROUP BY itc.whse_code, itc.item_id, itc.lot_id;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d3_itc_trans_qty(i) := 0;
            END;
--
          --ELSE   -- 2008/05/07 mod
          END IF;  -- 2008/05/07 mod 
--
            BEGIN
              -- D-4. �ړ��ϑ�����񒊏o
              IF (1 = curr_lot_ctl_tbl(i)) THEN
--
                -- ���b�g�Ǘ��i�ڂ̏ꍇ
                SELECT SUM(NVL(xmld.actual_quantity,0))                           --�B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
                INTO   ln_d4_quantity(i)
                FROM   xxinv_mov_req_instr_headers xmrih,                         --�@�ړ��˗�/�w���w�b�_(�A�h�I��)
                       xxinv_mov_req_instr_lines xmril,                           --�A�ړ��˗�/�w������(�A�h�I��)
                       xxinv_mov_lot_details xmld,                                --�B�ړ����b�g�ڍ�(�A�h�I��)
                       xxcmn_item_locations_v xilv                                --�C�DOPM�ۊǏꏊ���VIEW
                WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id               --�@�̈ړ��w�b�_id =�A�̈ړ��w�b�_id
                AND    xmril.mov_line_id         = xmld.mov_line_id               --�A�̈ړ�����id=�B�̖���id
                AND    xmrih.shipped_locat_id    = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
                AND    xilv.whse_code             = curr_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
                AND    xmril.item_id             = curr_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
-- 2008/11/11 Y.Kawano MOD Start
--                AND    xmrih.status              IN ('04','05')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
                AND    xmrih.status              IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
-- 2008/11/11 Y.Kawano MOD End
                AND    xmril.delete_flg          = 'N'                            --�A�̎���t���O= "off"
                AND    xmld.document_type_code   = '20'                           --�B�̕����^�C�v= "�ړ�"
                AND    xmld.record_type_code     = '20'                           --�B�̃��R�[�h�^�C�v= "�o�Ɏ���"
                -- 2008/05/07 mod ���tTRUNC�Ή� start
                --AND    xmrih.actual_ship_date    BETWEEN ld_invent_begin_ymd
                --                                 AND     ld_invent_end_ymd        --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
                --AND   (xmrih.actual_arrival_date > ld_invent_end_ymd              --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                --           OR xmrih.actual_arrival_date IS NULL                   --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
                --      )
                AND    TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                     AND TRUNC(ld_invent_end_ymd)     --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
                AND   (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                           OR xmrih.actual_arrival_date IS NULL                   --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
                      )
                -- 2008/05/07 mod ���tTRUNC�Ή� end
                AND    xmld.lot_id               = curr_lot_id_tbl(i)             --�B�̃��b�gid = d-2�Ŏ擾�������b�gid
                GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
              ELSE
--
                -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
                SELECT SUM(NVL(xmril.shipped_quantity,0))                         --�A�ړ��˗�/�w������(�A�h�I��)�̏o�Ɏ��ѐ���
                INTO   ln_d4_quantity(i)
                FROM   xxinv_mov_req_instr_headers xmrih,                         --�@�ړ��˗�/�w���w�b�_(�A�h�I��)
                       xxinv_mov_req_instr_lines xmril,                           --�A�ړ��˗�/�w������(�A�h�I��)
                       xxcmn_item_locations_v xilv                                --�C�DOPM�ۊǏꏊ���VIEW
                WHERE  xmrih.mov_hdr_id          = xmril.mov_hdr_id               --�@�̈ړ��w�b�_id =�A�̈ړ��w�b�_id
                AND    xmrih.shipped_locat_id    = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
                AND    xilv.whse_code             = curr_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
                AND    xmril.item_id             = curr_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
-- 2008/11/11 Y.Kawano MOD Start
--                AND    xmrih.status              IN ('04','05')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
                AND    xmrih.status              IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
-- 2008/11/11 Y.Kawano MOD End
                AND    xmril.delete_flg          = 'N'                            --�A�̎���t���O= "off"
                -- 2008/05/07 mod ���tTRUNC�Ή� start
                --AND    xmrih.actual_ship_date    BETWEEN ld_invent_begin_ymd
                --                                 AND     ld_invent_end_ymd        --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
                --AND   (xmrih.actual_arrival_date > ld_invent_end_ymd              --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                --       OR xmrih.actual_arrival_date IS NULL                       --�@�̓��Ɏ��ѓ�= �w��Ȃ�
                --      )
                AND    TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                 AND TRUNC(ld_invent_end_ymd)      --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
                AND   (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)              --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                       OR xmrih.actual_arrival_date IS NULL                        --�@�̓��Ɏ��ѓ�= �w��Ȃ�
                      )
                -- 2008/05/07 mod ���tTRUNC�Ή� end
                GROUP BY xilv.whse_code, xmril.item_code;
--
              END IF;
--
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                ln_d4_quantity(i):=0;
            END;
--
--          END IF;  -- 2008/05/07 mod
--
          BEGIN
--              
            -- D-5. �o�ׁE�L���ϑ�����񒊏o
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
--
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO  ln_d5_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- �@�󒍃w�b�_�A�h�I��
                    xxwsh_order_lines_all xola,                                   -- �A�󒍖��׃A�h�I��
                    xxinv_mov_lot_details xmld,                                   -- �B�ړ����b�g�ڍ�(�A�h�I��)
                    xxcmn_item_locations_v xilv,                                  -- �C�DOPM�ۊǏꏊ���VIEW
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib                                       -- �E�i�ڃ}�X�^
                    ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xola.order_line_id           = xmld.mov_line_id               -- �A�̎󒍖��׃A�h�I��ID    = �B�̖���ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code                = curr_whse_code_tbl(i)         -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- �A�̏o�וi��ID= �E�̕i��ID
--              AND   msib.segment1                = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   iimb.item_id                 = xmld.item_id                   -- �E�̕i��ID    = D-2�Ŏ擾�����i��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
              AND   xoha.req_status              IN ('04','08')                   -- �@�̃X�e�[�^�X= "�o�׎��ьv���"
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   xmld.document_type_code      IN ('10','30')                   -- �B�̕����^�C�v= "�o�׈˗�" �܂��� "�x���w��"
              AND   xmld.record_type_code        = '20'                           -- �B�̃��R�[�h�^�C�v = "�o�Ɏ���"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xoha.shipped_date            BETWEEN ld_invent_begin_ymd
              --                                   AND     ld_invent_end_ymd        -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              --AND  (xoha.arrival_date            > ld_invent_end_ymd              -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
              --      OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                             AND     TRUNC(ld_invent_end_ymd)     -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                    OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� end
              AND   xmld.lot_id = curr_lot_id_tbl(i)                              -- �B�̃��b�gid = d-2�Ŏ擾�������b�gid
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- �E�g�DID = �v���t�@�C���F�}�X�^�g�DID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- �A�󒍖��׃A�h�I��(�A�h�I��)�̏o�Ɏ��ѐ���
              INTO  ln_d5_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- �@�󒍃w�b�_�A�h�I��
                    xxwsh_order_lines_all xola,                                   -- �A�󒍖��׃A�h�I��
                    xxcmn_item_locations_v xilv,                                  -- �C�DOPM�ۊǏꏊ���VIEW      
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib,                                      -- �E�i�ڃ}�X�^
                    ic_item_mst_b iimb,                                           -- �E�i�ڃ}�X�^
-- 2008/10/02 v1.7 Y.Yamamoto Update End
	                  xxcmn_item_mst_v ximv                                         -- OPM�i�ڏ��VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   msib.segment1                = ximv.item_no
              AND   iimb.item_no                 = ximv.item_no
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xilv.whse_code               = curr_whse_code_tbl(i)          -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- �A�̏o�וi��ID= �E�̕i��ID
--              AND   msib.segment1                = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xoha.req_status              IN ('04','08')                   -- �@�̃X�e�[�^�X= "�o�׎��ьv���"
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xoha.shipped_date            BETWEEN ld_invent_begin_ymd
              --                                   AND     ld_invent_end_ymd        -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              --AND  (xoha.arrival_date            > ld_invent_end_ymd              -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
              --      OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                                 AND TRUNC(ld_invent_end_ymd)        -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                    OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� end
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- �E�g�DID = �v���t�@�C���F�}�X�^�g�DID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d5_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add start
          BEGIN
            -- D-12. �ړ��ϑ�����񒊏o ����
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO   ln_d12_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxinv_mov_lot_details xmld                                   --�B�ړ����b�g�ڍ�(�A�h�I��)
                    ,xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmril.mov_line_id       = xmld.mov_line_id               --�A�̈ړ�����id=�B�̖���id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code          = curr_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id           = curr_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
              AND   xmrih.status           IN ('04','06')                    --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   xmld.document_type_code = '20'                           --�B�̕����^�C�v= "�ړ�"
              AND   xmld.record_type_code   = '20'                           --�B�̃��R�[�h�^�C�v= "�o�Ɏ���"
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                  AND TRUNC(ld_invent_end_ymd)     --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                       OR xmrih.actual_arrival_date IS NULL                   --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
                   )
              AND  xmld.lot_id = curr_lot_id_tbl(i)                               --�B�̃��b�gid = d-6�Ŏ擾�������b�gid
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --�A�ړ��˗�/�w������(�A�h�I��)�̏o�Ɏ��ѐ���
              INTO   ln_d12_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code          = curr_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id           = curr_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
              AND   xmrih.status           IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_invent_begin_ymd)
                                                  AND TRUNC(ld_invent_end_ymd)     --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_invent_end_ymd)    --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                       OR xmrih.actual_arrival_date IS NULL                   --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
                   )
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d12_quantity(i):=0;
          END;
--
          BEGIN
            -- D-13.�o�ׁE�L���ϑ�����񒊏o
            lv_item_cd := TO_CHAR(curr_item_no_tbl(i));
--
            IF (1 = curr_lot_ctl_tbl(i)) THEN
--
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO  ln_d13_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxinv_mov_lot_details xmld                                   -- �B�ړ����b�g�ڍ�(�A�h�I��)
                   ,xxcmn_item_locations_v xilv                                  -- �C�DOPM�ۊǏꏊ���VIEW   
                   ,ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xola.order_line_id           = xmld.mov_line_id               -- �A�̎󒍖��׃A�h�I��ID    = �B�̖���ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code               = curr_whse_code_tbl(i)         -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   iimb.item_id                 = xmld.item_id                   -- �E�̕i��ID    = D-2�Ŏ擾�����i��ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   xmld.document_type_code     IN ('10','30')                   -- �B�̕����^�C�v= "�o�׈˗�" �܂��� "�x���w��"
              AND   xmld.record_type_code        = '20'                           -- �B�̃��R�[�h�^�C�v = "�o�Ɏ���"
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                      AND     TRUNC(ld_invent_end_ymd)     -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                    OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
                   )
              AND   xmld.lot_id = curr_lot_id_tbl(i)                              -- �B�̃��b�gid = d-2�Ŏ擾�������b�gid
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- �A�󒍖��׃A�h�I���̏o�Ɏ��ѐ���
              INTO  ln_d13_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxcmn_item_locations_v xilv                                  -- �C�DOPM�ۊǏꏊ���VIEW   
                   ,ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
                   ,xxcmn_item_mst_v ximv                                       -- OPM�i�ڏ��VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code               = curr_whse_code_tbl(i)         -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = ximv.item_no
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   xoha.shipped_date BETWEEN TRUNC(ld_invent_begin_ymd)
                                      AND     TRUNC(ld_invent_end_ymd)     -- �@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_invent_end_ymd)           -- �@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N��
                    OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
                   )
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d13_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add end
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
--        END LOOP current_cargo_cur;
        END LOOP D2_loop;
--
--        CLOSE current_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Update End
--
      EXCEPTION
        -- *** �����s�Ԗ߃n���h�� ***
        WHEN TOO_MANY_ROWS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** �l�G���[�n���h�� ***
        WHEN VALUE_ERROR THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** �[�����Z�G���[�n���h�� ***
        WHEN ZERO_DIVIDE THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
        -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE current_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--           RAISE global_process_expt;
             RAISE;
--mod end 1.2
    END;
    -- �������I���
--
    -- �O���n�܂�
    -- �莝���ʏ��i�O�����j���擾�ł��Ă���ꍇ
    -- D-6�����s
--
    BEGIN
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
      <<D6_loop>>
      lv_D6sql := 
           'SELECT xilv.whse_code              whse_code '   -- OPM�莝����  �q�ɃR�[�h
        || '      ,iimb.item_id                item_id '     -- OPM�i�ڃ}�X�^  �i��ID
        || '      ,iimb.item_no                item_no '     -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
        || '      ,ilm.lot_id                  lot_id '      -- OPM���b�g�}�X�^  ���b�gID
        || '      ,ilm.lot_no                  lot_no '      -- OPM���b�g�}�X�^  ���b�gNo
        || '      ,iimb.lot_ctl                lot_ctl '     -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
        || '      ,SUM(NVL(ipb.loct_onhand,0)) loct_onhand ' -- OPM�莝����  �莝����
        || 'FROM   ic_perd_bal ipb '                         -- OPM���b�g�ʌ����݌� (��D-2�ƈႤ)
        || '      ,xxcmn_item_locations_v   xilv '           -- OPM�ۊǏꏊ���VIEW
--2008/09/24 Y.Kawano Mod Start
--        || '      ,org_acct_periods         oap '            -- �݌ɉ�v����
        || '      ,ic_cldr_dtl                 icd '         -- OPM�݌ɃJ�����_�ڍ�
        || '      ,ic_whse_sts                 iws '         -- OPM�q�ɕʃJ�����_
--2008/09/24 Y.Kawano Mod End
        || '      ,ic_item_mst_b            iimb '           -- OPM�i�ڃ}�X�^
        || '      ,xxcmn_item_mst_b         ximb '           -- OPM�i�ڃA�h�I���}�X�^
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� start *----------*
        || '      ,ic_lots_mst              ilm '            -- OPM���b�g�}�X�^
        || '      ,xxinv_lots_notzero_mst_v xlmv '           -- �莝������b�gVIEW
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� end   *----------*
        || '      ,xxcmn_item_categories5_v xicv '           -- OPM�i�ڃJ�e�S���������VIEW1
        || 'WHERE  xicv.prod_class_code     = :arti_div_code '
        || 'AND    xicv.item_class_code     = :item_class_code '
        || 'AND    iimb.item_id             = xicv.item_id '
        || 'AND    iimb.item_id             = ximb.item_id '
        || 'AND    iimb.inactive_ind       <> ''1'' '
        || 'AND    ximb.obsolete_class     <> ''1'' '
        || 'AND    ximb.start_date_active  <= TRUNC(SYSDATE) '
        || 'AND    ximb.end_date_active    >= TRUNC(SYSDATE) '
        || 'AND    ilm.item_id              = iimb.item_id '    -- OPM���b�g�}�X�^.�i��ID   = OPM�i�ڃ}�X�^.�i��ID
--2008/09/24 Y.Kawano Mod Start
--        || 'AND    oap.period_start_date    = to_date(''' || ld_pre_invent_begin_ymd || ''',''YYYY/MM/DD HH24:MI:SS'')'
--        || 'AND    xilv.mtl_organization_id = oap.organization_id ';
        || 'AND    SUBSTRB( TO_CHAR(icd.period_end_date,''YYYYMM''),1,6) = ''' || lv_pre_invent_ym || ''''
        || 'AND    icd.period_id            = iws.period_id '
        || 'AND    xilv.whse_code           = iws.whse_code ';
--2008/09/24 Y.Kawano Mod End
--
      -- SQL�{�̂ƃp�����[�^������
      IF (lv_loc_where IS NOT NULL) THEN
        -- �q�ɃR�[�h�A�u���b�N�A�q�ɊǗ��������w�肳�ꂽ
        lv_D6sql := lv_D6sql
          || ' AND '
          || lv_loc_where;
      END IF;
      -- �w�肳��Ȃ�������WHERE��͍쐬���Ȃ�
--
      lv_D6sql := lv_D6sql
        || 'AND    ipb.item_id     = iimb.item_id '
        || 'AND    ipb.whse_code   = xilv.whse_code '
        || 'AND    ipb.lot_id      = ilm.lot_id '
        || 'AND    ipb.location    = xilv.segment1 '            -- add 2008/05/07 #47�Ή�
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� start *----------*
        || 'AND    ipb.item_id     = xlmv.item_id '
        || 'AND    ipb.lot_id      = xlmv.lot_id '
        || 'AND    ipb.whse_code   = xlmv.whse_code '
        || 'AND    ipb.location    = xlmv.location '
-- *----------* 2009/09/10 Ver.1.11 �{��#1607�Ή� end   *----------*
--2008/09/24 Y.Kawano Mod Start
--        || 'AND    ipb.fiscal_year = to_char(oap.period_year) ' -- mod 2008/05/07 #62�Ή�
--        || 'AND    ipb.period      = oap.period_num '
        || 'AND    ipb.fiscal_year = icd.fiscal_year '
        || 'AND    ipb.period      = icd.period '
--2008/09/24 Y.Kawano Mod End
        || 'GROUP BY '
        || '      xilv.whse_code '
        || '     ,iimb.item_id '
        || '     ,iimb.item_no '
        || '     ,ilm.lot_id '
        || '     ,ilm.lot_no '
        || '     ,iimb.lot_ctl ';
--
--      OPEN pre_cargo_cur(ld_pre_invent_begin_ymd);-- �J�[�\���I�[�v��
        OPEN  lrec_D6data FOR lv_D6sql
        USING iv_arti_div_code
             ,iv_item_class_code;
        FETCH lrec_D6data BULK COLLECT INTO lr_pre_cargo_rec;
        CLOSE lrec_D6data;
--
--        i := 0;
--        LOOP
         -- ���R�[�h�Ǎ�
--          FETCH pre_cargo_cur INTO lr_pre_cargo_rec;
--          EXIT WHEN pre_cargo_cur%NOTFOUND;
        <<D2_loop>>
        FOR i IN 1 .. lr_pre_cargo_rec.COUNT LOOP
--
--          i := i + 1;
-- 2008/09/16 v1.5 Y.Yamamoto Update End
          pre_whse_code_tbl(i)   := lr_pre_cargo_rec(i).whse_code;    -- OPM�莝����  �q�ɃR�[�h
          pre_item_id_tbl(i)     := lr_pre_cargo_rec(i).item_id;      -- OPM�i�ڃ}�X�^  �i��ID
          pre_item_no_tbl(i)     := lr_pre_cargo_rec(i).item_no;      -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
          pre_lot_id_tbl(i)      := lr_pre_cargo_rec(i).lot_id;       -- OPM���b�g�}�X�^  ���b�gID
          pre_lot_no_tbl(i)      := lr_pre_cargo_rec(i).lot_no;       -- OPM���b�g�}�X�^  ���b�gNo
          pre_lot_ctl_tbl(i)     := lr_pre_cargo_rec(i).lot_ctl;      -- OPM�i�ڃ}�X�^  ���b�g�Ǘ��敪
          pre_loct_onhand_tbl(i)  := lr_pre_cargo_rec(i).loct_onhand; -- OPM�莝����  �莝����
--
--add start 1.3
          add_del_info(
            lr_pre_cargo_rec(i).whse_code
           ,lr_pre_cargo_rec(i).item_id
           ,lv_pre_invent_ym
          );
--add end 1.3
          ln_d7_quantity(i):=0;
          ln_d8_quantity(i):=0;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          ln_d14_quantity(i) := 0;
          ln_d15_quantity(i) := 0;
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
          BEGIN
            -- D-7. �ړ��ϑ�����񒊏o�i�O�����j
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             --�B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO  ln_d7_quantity(i)
              FROM  xxinv_mov_req_instr_headers xmrih,                            --�@�ړ��˗�/�w���w�b�_(�A�h�I��)
                    xxinv_mov_req_instr_lines xmril,                              --�A�ړ��˗�/�w������(�A�h�I��)
                    xxinv_mov_lot_details xmld,                                   --�B�ړ����b�g�ڍ�(�A�h�I��)
                    xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id             = xmril.mov_hdr_id               --�@�̈ړ��w�b�_id =�A�̈ړ��w�b�_id
              AND   xmril.mov_line_id            = xmld.mov_line_id               --�A�̈ړ�����id=�B�̖���id
              AND   xmrih.shipped_locat_id       = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code               = pre_whse_code_tbl(i)           --�C�̑q�ɃR�[�h= d-6�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id                = pre_item_id_tbl(i)             --�A�̕i��id= d-6�Ŏ擾�����i��id
-- 2008/11/11 Y.Kawano MOD Start
--              AND   xmrih.status                 IN ('04','05')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND    xmrih.status              IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
-- 2008/11/11 Y.Kawano MOD End
              AND   xmril.delete_flg             = 'N'                            --�A�̎���t���O= "off"
              AND   xmld.document_type_code      = '20'                           --�B�̕����^�C�v= "�ړ�"
              AND   xmld.record_type_code        = '20'                           --�B�̃��R�[�h�^�C�v= "�o�Ɏ���"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xmrih.actual_ship_date       BETWEEN ld_pre_invent_begin_ymd
              --                                   AND     ld_pre_invent_end_ymd    --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              --AND  (xmrih.actual_arrival_date    > ld_pre_invent_end_ymd          --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
              --      OR xmrih.actual_arrival_date IS NULL                          --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
              --     )
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND     TRUNC(ld_pre_invent_end_ymd)  --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)     --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xmrih.actual_arrival_date IS NULL                          --�@�̓��Ɏ��ѓ�= �w��Ȃ�  
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� end
              AND   xmld.lot_id = pre_lot_id_tbl(i)                               --�B�̃��b�gid = d-6�Ŏ擾�������b�gid
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --�A�ړ��˗�/�w������(�A�h�I��)�̏o�Ɏ��ѐ���
              INTO ln_d7_quantity(i)
              FROM  xxinv_mov_req_instr_headers xmrih,                            --�@�ړ��˗�/�w���w�b�_(�A�h�I��)
                    xxinv_mov_req_instr_lines xmril,                              --�A�ړ��˗�/�w������(�A�h�I��)
                    xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id             = xmril.mov_hdr_id               --�@�̈ړ��w�b�_id =�A�̈ړ��w�b�_id
              AND   xmrih.shipped_locat_id       = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code               = pre_whse_code_tbl(i)           --�C�̑q�ɃR�[�h= d-6�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id                = pre_item_id_tbl(i)             --�A�̕i��id= d-6�Ŏ擾�����i��id
-- 2008/11/11 Y.Kawano MOD Start
--              AND   xmrih.status                 IN ('04','05')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND    xmrih.status              IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
-- 2008/11/11 Y.Kawano MOD End
              AND   xmril.delete_flg             = 'N'                            --�A�̎���t���O= "off"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xmrih.actual_ship_date       BETWEEN ld_pre_invent_begin_ymd
              --                                   AND     ld_pre_invent_end_ymd    --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              --AND  (xmrih.actual_arrival_date    > ld_pre_invent_end_ymd          --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
              --      OR xmrih.actual_arrival_date IS NULL                          --�@�̓��Ɏ��ѓ�= �w��Ȃ�
              --     )
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xmrih.actual_arrival_date IS NULL                              --�@�̓��Ɏ��ѓ�= �w��Ȃ�
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� end
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d7_quantity(i):=0;
          END;
--
          BEGIN
--
            -- D-8. �o�ׁE�L���ϑ�����񒊏o�i�O�����j
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO  ln_d8_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- �@�󒍃w�b�_�A�h�I��
                    xxwsh_order_lines_all xola,                                   -- �A�󒍖��׃A�h�I��
                    xxinv_mov_lot_details xmld,                                   -- �B�ړ����b�g�ڍ�(�A�h�I��)
                    xxcmn_item_locations_v xilv,                                  -- �C�DOPM�ۊǏꏊ���VIEW   
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib                                       -- �E�i�ڃ}�X�^
                    ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xola.order_line_id           = xmld.mov_line_id               -- �A�̎󒍖��׃A�h�I��ID    = �B�̖���ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code                = pre_whse_code_tbl(i)          -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- �A�̏o�וi��ID= �E�̕i��ID
--              AND   msib.segment1                = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   iimb.item_id                 = xmld.item_id                   -- �E�̕i��ID    = D-2�Ŏ擾�����i��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xoha.req_status              IN ('04','08')                   -- �@�̃X�e�[�^�X= "�o�׎��ьv���"
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   xmld.document_type_code      IN ('10','30')                   -- �B�̕����^�C�v= "�o�׈˗�" �܂��� "�x���w��"
              AND   xmld.record_type_code        = '20'                           -- �B�̃��R�[�h�^�C�v = "�o�Ɏ���"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xoha.shipped_date            BETWEEN ld_pre_invent_begin_ymd 
              --                                   AND     ld_pre_invent_end_ymd    -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              --AND  (xoha.arrival_date            > ld_pre_invent_end_ymd          -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
              --      OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xoha.arrival_date IS NULL                                    -- �@�̒��ד�=�w��Ȃ�
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� end
              AND   xmld.lot_id = pre_lot_id_tbl(i)                               -- �B�̃��b�gid = d-2�Ŏ擾�������b�gid
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- �E�g�DID = �v���t�@�C���F�}�X�^�g�DID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- �A�󒍖��׃A�h�I���̏o�Ɏ��ѐ���
              INTO  ln_d8_quantity(i)
              FROM  xxwsh_order_headers_all xoha,                                 -- �@�󒍃w�b�_�A�h�I��
                    xxwsh_order_lines_all xola,                                   -- �A�󒍖��׃A�h�I��
                    xxcmn_item_locations_v xilv,                                  -- �C�DOPM�ۊǏꏊ���VIEW   
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--                    mtl_system_items_b msib,                                      -- �E�i�ڃ}�X�^
                    ic_item_mst_b iimb,                                           -- �E�i�ڃ}�X�^
-- 2008/10/02 v1.7 Y.Yamamoto Update End
	                  xxcmn_item_mst_v ximv                                       -- OPM�i�ڏ��VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   msib.segment1                = ximv.item_no
              AND   iimb.item_no                 = ximv.item_no
-- 2008/10/02 v1.7 Y.Yamamoto Update End
              AND   xilv.whse_code                = pre_whse_code_tbl(i)          -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
--              AND   xola.shipping_inventory_item_id = msib.inventory_item_id      -- �A�̏o�וi��ID= �E�̕i��ID
--              AND   msib.segment1                = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
-- 2008/10/02 v1.7 Y.Yamamoto Update Start
              AND   xoha.req_status              IN ('04','08')                   -- �@�̃X�e�[�^�X= "�o�׎��ьv���"
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              -- 2008/05/07 mod ���tTRUNC�Ή� start
              --AND   xoha.shipped_date            BETWEEN ld_pre_invent_begin_ymd 
              --                                   AND     ld_pre_invent_end_ymd    -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              --AND  (xoha.arrival_date            > ld_pre_invent_end_ymd          -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
              --      OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
              --     )
-- 2008/08/28 Mod
--              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
              AND   xoha.shipped_date BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)    -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)       -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xoha.arrival_date IS NULL                                  -- �@�̒��ד�=�w��Ȃ�
                   )
              -- 2008/05/07 mod ���tTRUNC�Ή� start
-- 2008/10/02 v1.7 Y.Yamamoto Delete Start
--              AND   msib.organization_id         = lv_orgid_div                   -- �E�g�DID = �v���t�@�C���F�}�X�^�g�DID
-- 2008/10/02 v1.7 Y.Yamamoto Delete End
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d8_quantity(i):=0;
          END;
-- 2008/12/12 v1.9 Y.Yamamoto add start
          BEGIN
            -- D-14. �ړ��ϑ�����񒊏o ���ʑO����
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO   ln_d14_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxinv_mov_lot_details xmld                                   --�B�ړ����b�g�ڍ�(�A�h�I��)
                    ,xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmril.mov_line_id       = xmld.mov_line_id               --�A�̈ړ�����id=�B�̖���id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code          = pre_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id           = pre_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
              AND   xmrih.status           IN ('04','06')                    --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   xmld.document_type_code = '20'                           --�B�̕����^�C�v= "�ړ�"
              AND   xmld.record_type_code   = '20'                           --�B�̃��R�[�h�^�C�v= "�o�Ɏ���"
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xmrih.actual_arrival_date IS NULL                              --�@�̓��Ɏ��ѓ�= �w��Ȃ�
                   )
              AND  xmld.lot_id = pre_lot_id_tbl(i)                               --�B�̃��b�gid = d-6�Ŏ擾�������b�gid
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xmril.shipped_quantity,0))                           --�A�ړ��˗�/�w������(�A�h�I��)�̏o�Ɏ��ѐ���
              INTO   ln_d14_quantity(i)
              FROM   xxinv_mov_req_instr_headers xmrih
                    ,xxinv_mov_req_instr_lines xmril
                    ,xxcmn_item_locations_v xilv                                   --�C�DOPM�ۊǏꏊ���VIEW 
              WHERE xmrih.mov_hdr_id        = xmril.mov_hdr_id
              AND   xmrih.shipped_locat_id  = xilv.inventory_location_id     --�@�̏o�Ɍ�id=�D�̕ۊǑq��id
              AND   xilv.whse_code          = pre_whse_code_tbl(i)         --�C�̑q�ɃR�[�h= d-2�Ŏ擾�����q�ɃR�[�h
              AND   xmril.item_id           = pre_item_id_tbl(i)            --�A�̕i��id= d-2�Ŏ擾�����i��id
              AND   xmrih.status           IN ('04','06')                   --�@�̃X�e�[�^�X=  "�o�ɕ񍐗L"�܂���"���o�ɕ񍐗L"
              AND   xmrih.comp_actual_flg   = 'N'
              AND   xmril.delete_flg        = 'N'
              AND   TRUNC(xmrih.actual_ship_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                  AND TRUNC(ld_pre_invent_end_ymd)    --�@�̏o�Ɏ��ѓ��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xmrih.actual_arrival_date) > TRUNC(ld_pre_invent_end_ymd)   --�@�̓��Ɏ��ѓ��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xmrih.actual_arrival_date IS NULL                              --�@�̓��Ɏ��ѓ�= �w��Ȃ�
                   )
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_xfer_mst ixm
                                     ,ic_tran_pnd itp
                               WHERE  itp.doc_type      = 'XFER'
                               AND    itp.completed_ind = 1
                               AND    itp.reason_code   = 'X122'
                               AND    itp.doc_id        = ixm.transfer_id
                               AND    ixm.attribute1    = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM            = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'TRNI'
                               AND    itc.reason_code = 'X122'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              AND  NOT EXISTS (SELECT 1
                               FROM   ic_jrnl_mst ijm
                                     ,ic_adjs_jnl iaj
                                     ,ic_tran_cmp itc
                               WHERE  itc.doc_type    = 'ADJI'
                               AND    itc.reason_code = 'X123'
                               AND    itc.doc_type    = iaj.trans_type
                               AND    itc.doc_id      = iaj.doc_id
                               AND    itc.doc_line    = iaj.doc_line
                               AND    iaj.journal_id  = ijm.journal_id
                               AND    ijm.attribute1  = TO_CHAR(xmril.mov_line_id)
                               AND    ROWNUM          = 1)
              GROUP BY xilv.whse_code, xmril.item_code;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d14_quantity(i):=0;
          END;
--
          BEGIN
            -- D-15.�o�ׁE�L���ϑ�����񒊏o�O����
            lv_item_cd := TO_CHAR(pre_item_no_tbl(i));
--
            IF (1 = pre_lot_ctl_tbl(i)) THEN
--
              -- ���b�g�Ǘ��i�ڂ̏ꍇ
              SELECT SUM(NVL(xmld.actual_quantity,0))                             -- �B�ړ����b�g�ڍ�(�A�h�I��)�̎��ѐ���
              INTO  ln_d15_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxinv_mov_lot_details xmld                                   -- �B�ړ����b�g�ڍ�(�A�h�I��)
                   ,xxcmn_item_locations_v xilv                                  -- �C�DOPM�ۊǏꏊ���VIEW   
                   ,ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xola.order_line_id           = xmld.mov_line_id               -- �A�̎󒍖��׃A�h�I��ID    = �B�̖���ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code               = pre_whse_code_tbl(i)         -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   iimb.item_id                 = xmld.item_id                   -- �E�̕i��ID    = D-2�Ŏ擾�����i��ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   xmld.document_type_code     IN ('10','30')                   -- �B�̕����^�C�v= "�o�׈˗�" �܂��� "�x���w��"
              AND   xmld.record_type_code        = '20'                           -- �B�̃��R�[�h�^�C�v = "�o�Ɏ���"
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xoha.arrival_date IS NULL                                    -- �@�̒��ד�=�w��Ȃ�
                   )
              AND   xmld.lot_id = pre_lot_id_tbl(i)                              -- �B�̃��b�gid = d-2�Ŏ擾�������b�gid
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, xmld.item_code, xmld.lot_no;
--
            ELSE
--
              -- ���b�g�Ǘ��i�ڈȊO�̏ꍇ
              SELECT SUM(NVL(xola.shipped_quantity,0))                            -- �A�󒍖��׃A�h�I���̏o�Ɏ��ѐ���
              INTO  ln_d15_quantity(i)
              FROM  xxwsh_order_headers_all xoha
                   ,xxwsh_order_lines_all xola
                   ,xxcmn_item_locations_v xilv                                  -- �C�DOPM�ۊǏꏊ���VIEW   
                   ,ic_item_mst_b iimb                                            -- �E�i�ڃ}�X�^
                   ,xxcmn_item_mst_v ximv                                       -- OPM�i�ڏ��VIEW
              WHERE xoha.order_header_id         = xola.order_header_id           -- �@�̎󒍃w�b�_�A�h�I��ID= �A�̎󒍃w�b�_�A�h�I��ID
              AND   xoha.deliver_from_id         = xilv.inventory_location_id     -- �@�̏o�׌�ID= �D�̕ۊǑq��ID
              AND   xilv.whse_code               = pre_whse_code_tbl(i)         -- �C�̑q�ɃR�[�h= D-2�Ŏ擾�����q�ɃR�[�h
              AND   iimb.item_no                 = lv_item_cd                     -- �E�̕i�ڃR�[�h= D-2�Ŏ擾�����i�ڃR�[�h
              AND   iimb.item_no                 = ximv.item_no
              AND   xola.shipping_item_code      = iimb.item_no                   -- �A�̏o�וi��ID= �E�̕i��ID
              AND   xoha.req_status             IN ('04','08')
              AND   xoha.actual_confirm_class    = 'N'
              AND   xoha.latest_external_flag    = 'Y'                            -- �@�̍ŐV�t���O= "ON"
              AND   xola.delete_flag             = 'N'                            -- �A�̍폜�t���O= "OFF"
              AND   TRUNC(xoha.shipped_date) BETWEEN TRUNC(ld_pre_invent_begin_ymd)
                                                 AND TRUNC(ld_pre_invent_end_ymd)   -- �@�̏o�ד��̔N��=�N���p�����[�^�̑Ώ۔N���̑O��
              AND  (TRUNC(xoha.arrival_date) > TRUNC(ld_pre_invent_end_ymd)         -- �@�̒��ד��̔N�����N���p�����[�^�̑Ώ۔N���̑O��
                    OR xoha.arrival_date IS NULL                                    -- �@�̒��ד�=�w��Ȃ�
                   )
              AND NOT EXISTS (SELECT 'X'
                              FROM   oe_order_headers_all ooha
                              WHERE  ooha.attribute1 = xoha.request_no
-- 2009/03/30 H.Iida ADD START �{�ԏ�Q#1346
                              AND    ooha.org_id     = TO_NUMBER(lv_org_id))
-- 2009/03/30 H.Iida ADD END
              GROUP BY xilv.whse_code, ximv.item_id;
--
            END IF;
--
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              ln_d15_quantity(i):=0;
          END;
--
-- 2008/12/12 v1.9 Y.Yamamoto add end
--
-- 2008/09/16 v1.5 Y.Yamamoto Update Start
--        END LOOP pre_cargo_cur;
        END LOOP D6_loop;
--      
--      CLOSE pre_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Update End
--
    EXCEPTION
      -- *** �����s�Ԗ߃n���h�� ***
      WHEN TOO_MANY_ROWS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** �l�G���[�n���h�� ***
      WHEN VALUE_ERROR THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** �[�����Z�G���[�n���h�� ***
      WHEN ZERO_DIVIDE THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
-- 2008/09/16 v1.5 Y.Yamamoto Delete Start
--           CLOSE pre_cargo_cur; -- �J�[�\���̃N���[�Y
-- 2008/09/16 v1.5 Y.Yamamoto Delete End
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
    END;
    -- �O�����I���
--
--del start 1.3
--    -- D-9. �I�������݌Ƀe�[�u�����b�N����
--    -- �e�[�u�����b�N�֐��Ăяo��
--    IF NOT (xxcmn_common_pkg.get_tbl_lock('XXINV','XXINV_STC_INVENTORY_MONTH_STCK')) THEN
--      -- ���^�[���E�R�[�h��FALSE���Ԃ��ꂽ�ꍇ�̓G���[
--      RAISE global_api_expt;
--    END IF;
--del end 1.3
--
    BEGIN
      -- D-10. �I�������݌ɏ��o�́i�폜�j
--
--mod start 1.3
--      -- D-2�����s
--      FORALL i IN 1 .. curr_whse_code_tbl.COUNT
--        DELETE FROM xxinv_stc_inventory_month_stck
--        WHERE whse_code = curr_whse_code_tbl(i) -- OPM�莝����  �q�ɃR�[�h
--        AND   item_id   = curr_item_id_tbl(i)   -- �i��ID
--        AND   invent_ym = iv_invent_ym;         --  �N���p�����[�^�̑Ώ۔N��
----
--      -- D-6�����s
--      FORALL i IN 1 .. pre_whse_code_tbl.COUNT
--        DELETE FROM xxinv_stc_inventory_month_stck
--        WHERE whse_code = pre_whse_code_tbl(i) -- OPM�莝����  �q�ɃR�[�h
--        AND   item_id   = pre_item_id_tbl(i)   -- �i��ID
--        AND   invent_ym = lv_pre_invent_ym;    -- �N���p�����[�^�̑Ώ۔N���̑O�N
--
      FOR i IN 1..del_info.COUNT LOOP
        OPEN cur_del FOR
          SELECT ROWID 
          FROM xxinv_stc_inventory_month_stck
          WHERE whse_code = del_info(i).whse_code
          AND   item_id = del_info(i).item_id
          AND   invent_ym = del_info(i).invent_ym
          FOR UPDATE NOWAIT
          ;
--
        DELETE FROM xxinv_stc_inventory_month_stck
        WHERE whse_code = del_info(i).whse_code
        AND   item_id = del_info(i).item_id
        AND   invent_ym = del_info(i).invent_ym
        ;
      END LOOP;
--mod end 1.3
      -- �I�������݌�ID�̎擾
      FOR i IN 1..curr_whse_code_tbl.COUNT LOOP
        SELECT xxinv_stc_invt_most_s1.NEXTVAL      -- �V�[�P���X
        INTO   curr_invent_monthly_stock_id(i)
        FROM   dual;
      END LOOP;
--
      -- D-11. �I�������݌ɏ��o�́i�o�^�j
      -- D-2�����s
      FORALL i IN 1 .. curr_whse_code_tbl.COUNT
        INSERT INTO xxinv_stc_inventory_month_stck
          (invent_monthly_stock_id
          ,whse_code
          ,item_id
          ,item_code
          ,lot_id
          ,lot_no
          ,monthly_stock
          ,cargo_stock
          ,invent_ym
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,program_update_date)
          ,program_update_date
          ,cargo_stock_not_stn)
-- 2008/12/12 v1.9 Y.Yamamoto update end
        VALUES (
           curr_invent_monthly_stock_id(i)       -- �I�������݌�ID
          ,curr_whse_code_tbl(i)                 -- OPM�莝����  �q�ɃR�[�h
          ,curr_item_id_tbl(i)                   -- OPM�i�ڃ}�X�^ �i��ID
          ,curr_item_no_tbl(i)                   -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
          ,curr_lot_id_tbl(i)                    -- OPM���b�g�}�X�^  ���b�gID
          ,curr_lot_no_tbl(i)                    -- OPM���b�g�}�X�^  ���b�gNo
          ,NVL(curr_loct_onhand_tbl(i),0) 
           + NVL(ln_d3_itp_trans_qty(i),0) 
           + NVL(ln_d3_itc_trans_qty(i),0)       -- �����݌ɐ�  �v�iOPM�莝����  �莝���ʁ{D-3. ���ʁj
          ,ln_d4_quantity(i) + ln_d5_quantity(i) -- �ϑ����݌ɐ��iD-4�̐��ʁ{D-5�̐��ʁj
          ,iv_invent_ym                          -- �p�����[�^�̑Ώ۔N��
          ,ln_user_id
          ,SYSDATE
          ,ln_user_id
          ,SYSDATE
          ,ln_login_id
          ,ln_conc_request_id
          ,ln_prog_appl_id
          ,ln_conc_program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,SYSDATE);
          ,SYSDATE
          ,ln_d12_quantity(i) + ln_d13_quantity(i)); -- �W���ɂȂ��ϑ����݌ɐ��iD-12�̐��ʁ{D-13�̐��ʁj
-- 2008/12/12 v1.9 Y.Yamamoto update end
--
      -- �I�������݌�ID�̎擾
      FOR i IN 1..pre_whse_code_tbl.COUNT LOOP
        SELECT xxinv_stc_invt_most_s1.NEXTVAL      -- �V�[�P���X
        INTO   pre_invent_monthly_stock_id(i)
        FROM   dual;
      END LOOP;
--
      -- D-6�����s
      FORALL i IN 1 .. pre_whse_code_tbl.COUNT
        INSERT INTO xxinv_stc_inventory_month_stck
          (invent_monthly_stock_id
          ,whse_code
          ,item_id
          ,item_code
          ,lot_id
          ,lot_no
          ,monthly_stock
          ,cargo_stock
          ,invent_ym
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,program_update_date)
          ,program_update_date
          ,cargo_stock_not_stn)
-- 2008/12/12 v1.9 Y.Yamamoto update end
        VALUES (
           pre_invent_monthly_stock_id(i)        -- �I�������݌�ID
          ,pre_whse_code_tbl(i)                  -- OPM�莝����  �q�ɃR�[�h
          ,pre_item_id_tbl(i)                    -- OPM�i�ڃ}�X�^ �i��ID
          ,pre_item_no_tbl(i)                    -- OPM�i�ڃ}�X�^  �i�ڃR�[�h
          ,pre_lot_id_tbl(i)                     -- OPM���b�g�}�X�^  ���b�gID
          ,pre_lot_no_tbl(i)                     -- OPM���b�g�}�X�^  ���b�gNo
          ,pre_loct_onhand_tbl(i)                -- �����݌ɐ�  �v�iOPM�莝����  �莝���ʁj
          ,NVL(ln_d7_quantity(i),0) 
           + NVL(ln_d8_quantity(i),0)            -- �ϑ����݌ɐ��iD-7�̐��ʁ{D-8�̐��ʁj
          ,lv_pre_invent_ym                      -- �p�����[�^�̑Ώ۔N���̑O��
          ,ln_user_id
          ,SYSDATE
          ,ln_user_id
          ,SYSDATE
          ,ln_login_id
          ,ln_conc_request_id
          ,ln_prog_appl_id
          ,ln_conc_program_id
-- 2008/12/12 v1.9 Y.Yamamoto update start
--          ,SYSDATE);
          ,SYSDATE
          ,ln_d14_quantity(i) + ln_d15_quantity(i)); -- �W���ɂȂ��ϑ����݌ɐ��iD-14�̐��ʁ{D-15�̐��ʁj
-- 2008/12/12 v1.9 Y.Yamamoto update end
--
        COMMIT; -- �R�~�b�g
--
    EXCEPTION
      -- *** �d���G���[�n���h�� ***
      WHEN DUP_VAL_ON_INDEX THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** �l�G���[�n���h�� ***
      WHEN VALUE_ERROR THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** ���l�ϊ��G���[�n���h�� ***
      WHEN INVALID_NUMBER THEN
--mod start 1.2
--         RAISE global_process_expt;
           RAISE;
--mod end 1.2
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
--add start 1.2
        ROLLBACK;
--add end 1.2
--mod start 1.2
--         RAISE global_del_ins_expt;
           RAISE;
--mod end 1.2
    END;
--
    RETURN gn_ret_nomal;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
--del start 1.2
/*
    WHEN global_process_expt THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
     -- *** �폜�E�o�^�G���[�n���h�� ***
    WHEN global_del_ins_expt THEN
      ROLLBACK;-- ���[���o�b�N
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
    -- *** ����api�֐���O�n���h�� ***
*/
--del end 1.2
    WHEN global_api_expt THEN
      RAISE_APPLICATION_ERROR
--mod start 1.2
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||'�I�������݌Ƀe�[�u�����b�N�����Ɏ��s���܂����B',1,5000),TRUE);
      RETURN gn_ret_lock_error;
--mod end 1.2
--del start 1.2
/*
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
      RETURN gn_ret_other_error;
*/
--del end 1.2
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
--mod start 1.2
--        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
        (-20001,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--mod end 1.2
      RETURN gn_ret_other_error;
   END create_snapshot;
--
--#####################################  �Œ蕔 END   ##########################################
--
END xxinv550004c;
/
