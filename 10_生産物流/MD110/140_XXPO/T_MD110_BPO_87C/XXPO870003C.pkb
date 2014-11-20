CREATE OR REPLACE PACKAGE BODY xxpo870003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo870003c(body)
 * Description      : �����P�����֏���
 * MD.050           : �d���P���^�W�������}�X�^�o�^ Issue1.0  T_MD050_BPO_870
 * MD.070           : �d���P���^�W�������}�X�^�o�^ Issue1.0  T_MD070_BPO_870
 * Version          : 1.5
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                       Description
 * --------------------------- ----------------------------------------------------------
 *  func_chk_item_no            �i�ڔԍ��̑��݃`�F�b�N
 *  func_chk_customer           �����̑��݃`�F�b�N
 *  func_create_sql             SQL�̐���
 *  proc_put_process_result     �������ʏo��
 *  proc_upd_price_headers_flg  �d��/�W���P���w�b�_�̕ύX�����t���O���X�V
 *  proc_put_po_log             �����ϔ������׏��o��
 *  proc_upd_lot_data           ���b�g�݌ɒP���X�V
 *  proc_upd_po_data            �������ׂ̍X�V
 *  proc_calc_data              �v�Z����
 *  proc_get_unit_price         �d���P���f�[�^�擾
 *  proc_get_lot_data           ���b�g�f�[�^�擾
 *  proc_get_po_data            �������׃f�[�^�擾
 *  proc_check_param            �p�����[�^�`�F�b�N
 *  proc_put_parameter_log      �O����(���̓p�����[�^���O�o�͏���)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/10    1.0   Y.Ishikawa       �V�K�쐬
 *  2008/05/01    1.1   Y.Ishikawa       �������ׁA�����[�����ׁA���b�g�}�X�^�̒P���ݒ��
 *                                       �����z�������P���ɏC��
 *  2008/05/07    1.2   Y.Ishikawa       �g���[�X�̎w�E�ɂāA�i�ڃ`�F�b�N����
 *                                       MTL_SYSTEM_ITEMS_B�̎Q�Ƃ��폜
 *  2008/05/09    1.3   Y.Ishikawa       main�̋N�����ԏo�͂ɂāA���t�̃t�H�[�}�b�g��
 *                                       'YYYY/MM/DD HH:MM:SS'��'YYYY/MM/DD HH24:MI:SS'�ɕύX
 *  2008/06/03    1.4   Y.Ishikawa       �d���P���}�X�^���������X�V���ɂP���݂̂����X�V����Ȃ�
 *                                       �s��Ή�
 *  2008/06/03    1.5   Y.Ishikawa       �d���P���}�X�^�̎x����R�[�h���o�^����Ă��Ȃ��ꍇ��
 *                                       �����Ɋ܂߂Ȃ��B
 *                                       ������P����NULL�̏ꍇ�́A0�Ƃ��Čv�Z����B
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
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  global_user_expt       EXCEPTION;        -- ���[�U�[�ɂĒ�`��������O
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo870003c';    -- �p�b�P�[�W��
  -- ���W���[��������
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';        -- ���W���[�������́FXXCMN ����
  gv_xxpo             CONSTANT VARCHAR2(100) := 'XXPO';         -- ���W���[�������́FXXPO �̔�
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gv_cat_set_goods_class        CONSTANT VARCHAR2(100) := '���i�敪' ;      -- ���i�敪
  gv_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;      -- �i�ڋ敪
--
  -- �N�C�b�N�R�[�h��
  gv_xxcmn_date_type  CONSTANT VARCHAR2(100) := 'XXCMN_UNIT_PRICE_DERIVING_DAY'; -- �d���P�����o��
--
  -- ���b�Z�[�W
  gv_msg_xxpo30036    CONSTANT VARCHAR2(100) := 'APP-XXPO-30036';  --  ���̓p�����[�^���b�Z�[�W
  gv_msg_xxpo10102    CONSTANT VARCHAR2(100) := 'APP-XXPO-10102';  --  ���̓p�����[�^�K�{�`�F�b�N
  gv_msg_xxpo10103    CONSTANT VARCHAR2(100) := 'APP-XXPO-10103';  --  ���̓p�����[�^���݃`�F�b�N
  gv_msg_xxpo10104    CONSTANT VARCHAR2(100) := 'APP-XXPO-10104';  --  ���̓p�����[�^���t�`�F�b�N
  gv_msg_xxpo10105    CONSTANT VARCHAR2(100) := 'APP-XXPO-10105';  --  ���̓p�����[�^��r�`�F�b�N
  gv_msg_xxpo30032    CONSTANT VARCHAR2(100) := 'APP-XXPO-30032';  --  �����Ϗo�̓��O
  gv_msg_xxpo30033    CONSTANT VARCHAR2(100) := 'APP-XXPO-30033';  --  ���o�����o�̓��O
  gv_msg_xxpo30031    CONSTANT VARCHAR2(100) := 'APP-XXPO-30031';  --  ���֌����o�̓��O
  gv_msg_xxpo30029    CONSTANT VARCHAR2(100) := 'APP-XXPO-30029';  --  ���d���P���o�̓��O
  gv_msg_xxpo30030    CONSTANT VARCHAR2(100) := 'APP-XXPO-30030';  --  �������o�̓��O
  gv_msg_xxpo10093    CONSTANT VARCHAR2(100) := 'APP-XXPO-10093';  --  �������擾�G���[
  gv_msg_xxcmn10018   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; --  API�G���[
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; --  ���b�N�G���[
--
  -- �g�[�N��
  gv_tkn_data_type          CONSTANT VARCHAR2(100) := 'DATE_TYPE';      -- ���t�^�C�v
  gv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';      -- �J�n��
  gv_tkn_data_to            CONSTANT VARCHAR2(100) := 'DATE_TO';        -- �I����
  gv_tkn_item_no            CONSTANT VARCHAR2(100) := 'ITEM_NO';        -- �i��
  gv_tkn_vendor_code        CONSTANT VARCHAR2(100) := 'VENDOR_CODE';    -- �����
  gv_tkn_item_category      CONSTANT VARCHAR2(100) := 'ITEM_CATEGORY';  -- �i�ڋ敪
  gv_tkn_goods_category     CONSTANT VARCHAR2(100) := 'GOODS_CATEGORY'; -- ���i�敪
  gv_tkn_param_name         CONSTANT VARCHAR2(100) := 'PARAM_NAME';     -- �p�����[�^��
  gv_tkn_param_value        CONSTANT VARCHAR2(100) := 'PARAM_VALUE';    -- �p�����[�^�l
  gv_tkn_target_count       CONSTANT VARCHAR2(100) := 'TARGET_COUNT';   -- �������׏������v����
  gv_tkn_count              CONSTANT VARCHAR2(100) := 'COUNT';          -- ���֌���
  gv_tkn_h_no               CONSTANT VARCHAR2(100) := 'H_NO';           -- �����ԍ�
  gv_tkn_m_no               CONSTANT VARCHAR2(100) := 'M_NO';           -- �������הԍ�
  gv_tkn_nonyu_date         CONSTANT VARCHAR2(100) := 'NONYU_DATE';     -- �[����
  gv_tkn_ng_h_no            CONSTANT VARCHAR2(100) := 'NG_H_NO';        -- NG�����ԍ�
  gv_tkn_ng_m_no            CONSTANT VARCHAR2(100) := 'NG_M_NO';        -- NG�������הԍ�
  gv_tkn_ng_item_no         CONSTANT VARCHAR2(100) := 'NG_ITEM_NO';     -- NG�i��
  gv_tkn_ng_nonyu_date      CONSTANT VARCHAR2(100) := 'NG_NONYU_DATE';  -- NG�[����
  gv_tkn_ng_count           CONSTANT VARCHAR2(100) := 'NG_COUNT';       -- NG����
  gv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';       -- API��
  gv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';          -- �e�[�u��
  gv_tkn_ng_profile         CONSTANT VARCHAR2(100) := 'NG_PROFILE';     -- NG_PROFILE
--
  gv_tkn_val_date_type      CONSTANT VARCHAR2(100) := '���t�^�C�v';
  gv_tkn_val_start_date     CONSTANT VARCHAR2(100) := '���ԊJ�n';
  gv_tkn_val_end_date       CONSTANT VARCHAR2(100) := '���ԏI��';
  gv_tkn_val_commodity_type CONSTANT VARCHAR2(100) := '���i�敪';
  gv_tkn_val_item_type      CONSTANT VARCHAR2(100) := '�i�ڋ敪';
  gv_tkn_val_item           CONSTANT VARCHAR2(100) := '�i��';
  gv_tkn_val_customer       CONSTANT VARCHAR2(100) := '�����';
--
  -- ���b�N�e�[�u����
  gv_po_line                CONSTANT VARCHAR2(100) := '��������';
  gv_po_location            CONSTANT VARCHAR2(100) := '�����[������';
  gv_lot_mst                CONSTANT VARCHAR2(100) := 'OPM���b�g�}�X�^';
  gv_price_headers          CONSTANT VARCHAR2(100) := '�d��/�W���P���w�b�_';
--
  -- ���t�t�H�[�}�b�g
  gv_format_yyyymmdd        CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';     -- YYYY/MM/DD
  gv_format_yyyymm          CONSTANT VARCHAR2(100) := 'YYYY/MM';        -- YYYYMM
  gv_dt_format              CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- YES/NO
  gv_y                      CONSTANT VARCHAR2(1) := 'Y';
  gv_n                      CONSTANT VARCHAR2(1) := 'N';
--
  -- ���t�^�C�v
  gv_mgc_day                CONSTANT VARCHAR2(1) := '1';   -- ������
  gv_deliver_day            CONSTANT VARCHAR2(1) := '2';   -- �[����
--
  -- �����敪
  gv_provision              CONSTANT VARCHAR2(1) := '3';   -- �x��
--
-- �v�Z����
  gn_100                    CONSTANT NUMBER(3)   := 100;   -- 100
--
-- ���K�敪
  gv_rate                   CONSTANT VARCHAR2(1) := '2';   -- ��
--
-- �����X�e�[�^�X
  gv_po_stats               CONSTANT VARCHAR2(2) := '25';   -- �������
--
-- �����ύXAPI
  gv_version                CONSTANT VARCHAR2(8) := '1.0'; -- �o�[�W����
  gn_zero                   CONSTANT NUMBER      := 0;     -- 0�G���[
--
-- �v�Z�t���O
  gn_depo_flg               NUMBER;                       -- �a����K���z�v�Z�t���O
  gn_cane_flg               NUMBER;                       -- ���ۋ��z�v�Z�t���O
--
  -- WHO�J����
  gn_user_id    po_lines_all.last_updated_by%TYPE   DEFAULT FND_GLOBAL.USER_ID;         -- հ�ްID
  gd_sysdate    po_lines_all.last_update_date%TYPE  DEFAULT SYSDATE;                    -- ���ѓ�
  gn_login_id   po_lines_all.last_update_login%TYPE DEFAULT FND_GLOBAL.LOGIN_ID;        -- ۸޲�ID
  gn_request_id po_lines_all.request_id%TYPE        DEFAULT FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
  gn_appl_id    po_lines_all.program_application_id%TYPE DEFAULT FND_GLOBAL.PROG_APPL_ID; -- APID
  gn_program_id po_lines_all.program_id%TYPE        DEFAULT FND_GLOBAL.CONC_PROGRAM_ID;   -- PGID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �������f�[�^
  TYPE get_rec_type IS RECORD (
    status               po_headers_all.attribute1%TYPE,              -- �X�e�[�^�X
    vendor_id            po_headers_all.vendor_id%TYPE,               -- �d����ID
    delivery_code        po_headers_all.attribute7%TYPE,              -- �z����R�[�h
    direct_sending_type  po_headers_all.attribute6%TYPE,              -- �����敪
    delivery_day         po_headers_all.attribute4%TYPE,              -- �[����
    po_no                po_headers_all.segment1%TYPE,                -- �����ԍ�
    revision_num         po_headers_all.revision_num%TYPE,            -- �o�[�W����
    po_line_id           po_lines_all.po_line_id%TYPE,                -- ��������ID
    po_l_no              po_lines_all.line_num%TYPE,                  -- �������הԍ�
    lot_no               po_lines_all.attribute1%TYPE,                -- ���b�g�ԍ�
    po_quantity          po_lines_all.attribute11%TYPE,               -- ��������
    rcv_quantity         po_lines_all.attribute7%TYPE,                -- �������
    fact_code            po_lines_all.attribute2%TYPE,                -- �H��R�[�h
    accompany_code       po_lines_all.attribute3%TYPE,                -- �t�уR�[�h
    base_uom             po_lines_all.unit_meas_lookup_code%TYPE,     -- ������P��
    po_uom               po_lines_all.attribute10%TYPE,               -- �����P��
    line_location_id     po_line_locations_all.line_location_id%TYPE, -- �[�����הԍ�
    shipment_num         po_line_locations_all.shipment_num%TYPE,     -- �[�����הԍ�
    powde_lead           po_line_locations_all.attribute1%TYPE,       -- ������
    commission_type      po_line_locations_all.attribute3%TYPE,       -- ���K�敪
    commission           po_line_locations_all.attribute4%TYPE,       -- ���K
    assessment_type      po_line_locations_all.attribute6%TYPE,       -- ���ۋ��敪
    assessment           po_line_locations_all.attribute7%TYPE,       -- ���ۋ�
    num_of_cases         xxcmn_item_mst_v.num_of_cases%TYPE,          -- �P�[�X����
    conv_unit            xxcmn_item_mst_v.conv_unit%TYPE,             -- ���o�Ɋ��Z�P��
    item_id              xxcmn_item_mst_v.item_id%TYPE,               -- �i��ID
    item_no              xxcmn_item_mst_v.item_no%TYPE,               -- �i�ڔԍ�
    cost_manage_code     xxcmn_item_mst_v.cost_manage_code%TYPE       -- �����Ǘ��敪
    );
--
  --���b�g���
  TYPE get_rec_lot IS RECORD (
    lot_id               ic_lots_mst.lot_id%TYPE,                     -- ���b�gID
    lot_desc             ic_lots_mst.lot_desc%TYPE,                   -- ���b�g�E�v
    qc_grade             ic_lots_mst.qc_grade%TYPE,                   -- �O���[�h
    expaction_code       ic_lots_mst.expaction_code%TYPE,             -- �����R�[�h
    expaction_date       ic_lots_mst.expaction_date%TYPE,             -- �������t
    lot_created          ic_lots_mst.lot_created%TYPE,                -- ���b�g�쐬��
    expire_date          ic_lots_mst.expire_date%TYPE,                -- ������
    retest_date          ic_lots_mst.retest_date%TYPE,                -- �ăe�X�g��
    strength             ic_lots_mst.strength%TYPE,                   -- ���x
    inactive_ind         ic_lots_mst.inactive_ind%TYPE,               -- �L���t���O
    shipvend_id          ic_lots_mst.shipvend_id%TYPE,                -- �d����ID
    vendor_lot_no        ic_lots_mst.vendor_lot_no%TYPE,              -- �d�����b�gNO
    create_day           ic_lots_mst.attribute1%TYPE,                 -- �����N����
    attribute2           ic_lots_mst.attribute2%TYPE,                 -- �ŗL�L��
    attribute3           ic_lots_mst.attribute3%TYPE,                 -- �ܖ�����
    attribute4           ic_lots_mst.attribute4%TYPE,                 -- �[�����i����j
    attribute5           ic_lots_mst.attribute5%TYPE,                 -- �[�����i�ŏI�j
    attribute6           ic_lots_mst.attribute6%TYPE,                 -- �݌ɓ���
    attribute7           ic_lots_mst.attribute7%TYPE,                 -- �݌ɒP��
    attribute8           ic_lots_mst.attribute8%TYPE,                 -- �����
    attribute9           ic_lots_mst.attribute9%TYPE,                 -- �d���`��
    attribute10          ic_lots_mst.attribute10%TYPE,                -- �����敪
    attribute11          ic_lots_mst.attribute11%TYPE,                -- �N�x
    attribute12          ic_lots_mst.attribute12%TYPE,                -- �Y�n
    attribute13          ic_lots_mst.attribute13%TYPE,                -- �^�C�v
    attribute14          ic_lots_mst.attribute14%TYPE,                -- �����N�P
    attribute15          ic_lots_mst.attribute15%TYPE,                -- �����N�Q
    attribute16          ic_lots_mst.attribute16%TYPE,                -- ���Y�`�[�敪
    attribute17          ic_lots_mst.attribute17%TYPE,                -- ���C����
    attribute18          ic_lots_mst.attribute18%TYPE,                -- �E�v
    attribute19          ic_lots_mst.attribute19%TYPE,                -- �����N�R
    attribute20          ic_lots_mst.attribute20%TYPE,                -- ���������H��
    attribute21          ic_lots_mst.attribute21%TYPE,                -- �������������b�g�ԍ�
    attribute22          ic_lots_mst.attribute22%TYPE,                -- �����˗�No
    attribute23          ic_lots_mst.attribute23%TYPE,                -- DFF23
    attribute24          ic_lots_mst.attribute24%TYPE,                -- DFF24
    attribute25          ic_lots_mst.attribute25%TYPE,                -- DFF25
    attribute26          ic_lots_mst.attribute26%TYPE,                -- DFF26
    attribute27          ic_lots_mst.attribute27%TYPE,                -- DFF27
    attribute28          ic_lots_mst.attribute28%TYPE,                -- DFF28
    attribute29          ic_lots_mst.attribute29%TYPE,                -- DFF29
    attribute30          ic_lots_mst.attribute30%TYPE,                -- DFF30
    attribute_category   ic_lots_mst.attribute_category%TYPE,         -- DFF23
    ic_hold_date         ic_lots_cpg.ic_hold_date%TYPE                -- �ێ���
    );
--
  -- ���̓p�����[�^
  TYPE gt_item_no    IS TABLE OF xxcmn_item_mst_v.item_no%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_vender_cd  IS TABLE OF xxcmn_vendors_v.segment1%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_item_id    IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE gt_vender_id  IS TABLE OF xxcmn_vendors_v.vendor_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- �d���P���w�b�_�[ID
  TYPE gt_p_header_id IS TABLE OF xxpo_price_headers.price_header_id%TYPE INDEX BY BINARY_INTEGER;
--
  TYPE g_rec_item IS RECORD(
    item_no            gt_item_no,     -- �i�ڃR�[�h
    item_id            gt_item_id      -- �i��ID
  );
--
  TYPE g_rec_vender IS RECORD(
    vender_code        gt_vender_cd,   -- �d����R�[�h
    vender_id          gt_vender_id    -- �d����ID
  );
--
  -- �������f�[�^
  TYPE get_po_tbl IS TABLE OF get_rec_type INDEX BY BINARY_INTEGER;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(g_rec_item)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      l_rec_item IN g_rec_item
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<item_loop>>
    FOR i IN 1..l_rec_item.item_id.COUNT LOOP
      lv_in := lv_in || TO_CHAR(l_rec_item.item_id(i)) || ',';
    END LOOP item_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
--
  END fnc_get_in_statement;
--
--
--
  /**********************************************************************************
   * Function Name    : fnc_get_in_statement
   * Description      : IN��̓��e��Ԃ��܂��B(g_rec_vender)
   ***********************************************************************************/
  FUNCTION fnc_get_in_statement(
      l_rec_vender IN g_rec_vender
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_get_in_statement' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_in          VARCHAR2(1000) ;
--
  BEGIN
--
    <<vender_loop>>
    FOR i IN 1..l_rec_vender.vender_id.COUNT LOOP
      lv_in := lv_in || TO_CHAR(l_rec_vender.vender_id(i)) || ',';
    END LOOP vender_loop;
--
    RETURN(
      SUBSTR(lv_in,1,LENGTH(lv_in) - 1));
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
--
  END fnc_get_in_statement;
--
  /**********************************************************************************
   * Function Name    : func_chk_item_no
   * Description      : �i�ڔԍ��̑��݃`�F�b�N
   ***********************************************************************************/
  FUNCTION func_chk_item_no(
    iv_item_no         IN     VARCHAR2)   -- �i�ڔԍ�
  RETURN NUMBER                          -- (�ߒl) �i��ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_chk_item_no'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_item_id  xxcmn_item_mst_v.inventory_item_id%TYPE DEFAULT NULL;        -- �i��ID
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- ==============================================================
    -- OPM�i�ڃ}�X�^�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT ximv.inventory_item_id item_id
      INTO   ln_item_id
      FROM   xxcmn_item_mst_v    ximv      -- OPM�i�ڏ��VIEW
      WHERE  ximv.item_no   = iv_item_no
      AND    ROWNUM         = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
            --���^�[��
        ln_item_id := NULL;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --���^�[��
    RETURN ln_item_id;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
  END func_chk_item_no;
--
--
  /**********************************************************************************
   * Function Name    : func_chk_customer
   * Description      : �����̑��݃`�F�b�N
   ***********************************************************************************/
  FUNCTION func_chk_customer(
    iv_customer_code   IN     VARCHAR2)   -- �d����ԍ�
  RETURN NUMBER                           -- (�ߒl) �d����ID
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_chk_customer'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    ln_vendor_id  xxcmn_vendors_v.vendor_id%TYPE DEFAULT NULL;       -- �d����ID
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- ==============================================================
    -- �d����}�X�^�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT xvv.vendor_id vendor_id
      INTO   ln_vendor_id
      FROM   xxcmn_vendors_v xvv           -- �d������VIEW
      WHERE  xvv.segment1 = iv_customer_code
      AND    ROWNUM      = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        ln_vendor_id := NULL;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    --���^�[��
    RETURN ln_vendor_id;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
  END func_chk_customer;
--
--
  /**********************************************************************************
   * Function Name    : func_create_sql
   * Description      : SQL�̐���
   ***********************************************************************************/
  FUNCTION func_create_sql(
    iv_date_type        IN  VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date       IN  VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date         IN  VARCHAR2,      -- ���ԏI����(YYYY/MM/DD)
    iv_goods_type_name  IN  VARCHAR2,      -- ���i�敪��
    iv_item_type_name   IN  VARCHAR2,      -- �i�ڋ敪��
    ir_item             IN  g_rec_item,    -- �i�ڏ��
    ir_vender           IN  g_rec_vender)  -- �������
  RETURN VARCHAR2                          -- (�ߒl) SQL��
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_create_sql'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_select_sql CONSTANT VARCHAR2(32767) :=
      ' SELECT  pha.attribute1            AS  status'                -- �X�e�[�^�X
          || ' ,pha.vendor_id             AS  vendor_id'             -- �d����ID
          || ' ,pha.attribute7            AS  delivery_code'         -- �z����R�[�h
          || ' ,pha.attribute6            AS  direct_sending_type'   -- �����敪
          || ' ,pha.attribute4            AS  delivery_day'          -- �[����
          || ' ,pha.segment1              AS  po_no'                 -- �����ԍ�
          || ' ,pha.revision_num          AS  revision_num'          -- �o�[�W����
          || ' ,pla.po_line_id            AS  po_line_id'            -- ��������ID
          || ' ,pla.line_num              AS  po_l_no'               -- �������הԍ�
          || ' ,pla.attribute1            AS  lot_no'                -- ���b�g�ԍ�
          || ' ,pla.attribute11           AS  po_quantity'           -- ��������
          || ' ,pla.attribute7            AS  rcv_quantity'          -- �������
          || ' ,pla.attribute2            AS  fact_code'             -- �H��R�[�h
          || ' ,pla.attribute3            AS  accompany_code'        -- �t�уR�[�h
          || ' ,pla.unit_meas_lookup_code AS  base_uom'              -- �����P��
          || ' ,pla.attribute10           AS  po_uom'                -- �����P��
          || ' ,plla.line_location_id     AS  line_location_id'      -- �[������ID
          || ' ,plla.shipment_num         AS  shipment_num'          -- �[�����הԍ�
          || ' ,NVL(plla.attribute1,'|| '''0''' || ')  AS  powde_lead' -- ������
          || ' ,plla.attribute3           AS  commission_type'       -- ���K�敪
          || ' ,plla.attribute4           AS  commission'            -- ���K
          || ' ,plla.attribute6           AS  assessment_type'       -- ���ۋ��敪
          || ' ,plla.attribute7           AS  assessment'            -- ���ۋ�
          || ' ,ximv.num_of_cases         AS  num_of_cases'          -- �P�[�X����
          || ' ,ximv.conv_unit            AS  conv_unit'             -- ���o�Ɋ��Z�P��
          || ' ,ximv.item_id              AS  item_id'               -- �i��ID
          || ' ,ximv.item_no              AS  item_no'               -- �i�ڔԍ�
          || ' ,ximv.cost_manage_code     AS  cost_manage_code';     -- �����Ǘ��敪
--
    cv_po_ok       CONSTANT VARCHAR2(10) := '20';                 -- �����쐬��
    cv_quantity_ok CONSTANT VARCHAR2(10) := '30';                 -- ���ʊm���
    cv_no          CONSTANT VARCHAR2(10) := 'N';                  -- N
    cv_one         CONSTANT VARCHAR2(10) := '01';                 -- 01��
--
    -- *** ���[�J���ϐ� ***
    lv_close_date        VARCHAR2(10)    DEFAULT NULL;            -- ��v�N���[�Y��
    lv_from_where_sql    VARCHAR2(32767) DEFAULT NULL;            -- WHERE��pSQL
    lv_and_sql1          VARCHAR2(32767) DEFAULT NULL;            -- AND��pSQL
    lv_and_sql2          VARCHAR2(32767) DEFAULT NULL;            -- AND��pSQL
    lv_and_sql3          VARCHAR2(32767) DEFAULT NULL;            -- AND��pSQL
    lv_and_sql4          VARCHAR2(32767) DEFAULT NULL;            -- AND��pSQL
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
    lv_in                VARCHAR2(1000)  DEFAULT NULL;            -- IN��
    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J���E�J�[�\�� ***
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
    -- ***********************************************
    -- ***      ���ʊ֐��������W�b�N�̋L�q         ***
    -- ***********************************************
--
    -- ��v�N���[�Y�̎擾
    lv_close_date := TO_CHAR(FND_DATE.STRING_TO_DATE(xxcmn_common_pkg.get_opminv_close_period
                             || cv_one,gv_format_yyyymmdd),gv_format_yyyymmdd);
    -- ===============================
    -- AND��쐬
    -- ===============================
    -- ���t�^�C�v����SQL����
    IF (iv_date_type = gv_deliver_day) THEN
      -- ���t�^�C�v���[�����̏ꍇ
      lv_and_sql2 := ' AND pha.attribute4 BETWEEN ' || '''' || iv_start_date || ''''
                  || ' AND ' || '''' || iv_end_date || '''';
    END IF;
--
    -- �i�ڏ���SQL����
    IF (ir_item.item_id.COUNT = 1) THEN
      -- 1���̂�
      lv_and_sql3 := ' AND pla.item_id = ' || TO_CHAR(ir_item.item_id(1));
    ELSIF (ir_item.item_id.COUNT > 0) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_item);
      lv_and_sql3 := ' AND pla.item_id IN('|| lv_in || ') ';
    ELSE
      NULL;
    END IF;
--
    -- ��������SQL����
    IF (ir_vender.vender_id.COUNT = 1) THEN
      -- 1���̂�
      lv_and_sql4 := ' AND pha.vendor_id = ' || TO_CHAR(ir_vender.vender_id(1));
    ELSIF (ir_vender.vender_id.COUNT > 0) THEN
      -- 1���ȏ�
      lv_in := fnc_get_in_statement(ir_vender);
      lv_and_sql4 := ' AND pha.vendor_id IN('|| lv_in || ') ';
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- WHERE��쐬
    -- ===============================
    lv_from_where_sql :=
      ' FROM   po_headers_all         pha'                    -- �����w�b�_
      ||     ' ,po_lines_all          pla'                    -- ��������
      ||     ' ,po_line_locations_all plla'                   -- �����[������
      ||     ' ,xxcmn_item_mst_v      ximv'                   -- OPM�i�ڏ��VIEW
      ||     ' WHERE  pha.attribute4 > ' || '''' || lv_close_date || ''''; -- �[����
--
    -- ����悪�p�����[�^�ɓ��͂���Ă����ꍇ�����ǉ�
    IF (lv_and_sql4 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql4;
    END IF;
--
    -- ���t�^�C�v���[�����̏ꍇ�����ǉ�
    IF (lv_and_sql2 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql2;
    END IF;
--
    lv_from_where_sql := lv_from_where_sql
      ||     ' AND pha.attribute1 BETWEEN ' || ''''|| cv_po_ok || ''''
      ||     ' AND ' || ''''||    cv_quantity_ok   || ''''              -- �X�e�[�^�X
      ||     ' AND pha.po_header_id  = pla.po_header_id ';              -- �����w�b�_ID
--
    -- �i�ڂ��p�����[�^�ɓ��͂���Ă����ꍇ�����ǉ�
    IF (lv_and_sql3 IS NOT NULL) THEN
      lv_from_where_sql := lv_from_where_sql || lv_and_sql3;
    END IF;
--
    lv_from_where_sql := lv_from_where_sql
      ||     ' AND pla.attribute14              = ' || ''''|| cv_no || ''''    -- ���z�m��t���O
      ||     ' AND pla.po_header_id             = plla.po_header_id'           -- �����w�b�_ID
      ||     ' AND pla.po_line_id               = plla.po_line_id'             -- ��������ID
      ||     ' AND pla.item_id                  = ximv.inventory_item_id'      -- �i��ID
      ||     ' AND xxcmn_common_pkg.get_category_desc(ximv.item_no,'
      ||     ''''|| gv_cat_set_item_class || '''' || ')  = ' || '''' || iv_item_type_name || ''''
      ||     ' AND xxcmn_common_pkg.get_category_desc(ximv.item_no,'
      ||     ''''|| gv_cat_set_goods_class || '''' || ') = ' || '''' || iv_goods_type_name || ''''
      ||     ' AND ximv.unit_price_calc_code      = ' || '''' || iv_date_type || ''''
      ||     ' FOR UPDATE OF pla.po_line_id,plla.line_location_id NOWAIT';
--
--
    -- SQL���̌���
    lv_sql := lv_select_sql || lv_from_where_sql;
--
    --���^�[��
    RETURN lv_sql;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
  END func_create_sql;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_process_result
   * Description      : �������ʏo��(C-11)
   ***********************************************************************************/
  PROCEDURE proc_put_process_result(
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_process_result'; -- �v���O������
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
    lv_out_msg       VARCHAR2(5000);
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
    -- �w��p�����[�^�̏����ɍ��v�����������׌����o��
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30033,
                    iv_token_name1  => gv_tkn_target_count,
                    iv_token_value1 => TO_CHAR(gn_target_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    -- ===============================
    -- �P�����X�V���������o��
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30031,
                    iv_token_name1  => gv_tkn_count,
                    iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    -- ===============================
    -- �d���P���f�[�^���擾�ł��Ȃ������������ׂ̌����o��
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30029,
                    iv_token_name1  => gv_tkn_ng_count,
                    iv_token_value1 => TO_CHAR(gn_warn_cnt)
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
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
  END proc_put_process_result;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_price_headers_flg
   * Description      : �d��/�W���P���w�b�_�̕ύX�����t���O���X�V(C-10)
   ***********************************************************************************/
  PROCEDURE proc_upd_price_headers_flg(
    in_price_header_id IN  xxcmn_vendors_v.vendor_id%TYPE, -- �w�b�_ID
    ov_errbuf          OUT VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_price_headers_flg'; -- �v���O������
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
    ln_result             NUMBER;                            -- API�֐��߂�l
    ltbl_api_errors       PO_API_ERRORS_REC_TYPE;            -- API�G���[�߂�l
    lv_out_msg            VARCHAR2(2000);                    -- ���O���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
    -- ===============================
    -- �d��/�W���P���w�b�_�̍X�V
    -- ===============================
    UPDATE xxpo_price_headers xpha                             -- �d��/�W���P���w�b�_
    SET    xpha.record_change_flg      = gv_n                  -- �ύX�����t���O
          ,xpha.last_updated_by        = gn_user_id            -- �ŏI�X�V��
          ,xpha.last_update_date       = gd_sysdate            -- �ŏI�X�V��
          ,xpha.last_update_login      = gn_login_id           -- �ŏI�X�V���O�C��
          ,xpha.request_id             = gn_request_id         -- �v��ID
          ,xpha.program_application_id = gn_appl_id            -- ���ع����ID
          ,xpha.program_id             = gn_program_id         -- �v���O����ID
          ,xpha.program_update_date    = gd_sysdate            -- �v���O�����X�V��
    WHERE xpha.price_header_id         = in_price_header_id    -- �w�b�_ID
    ;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_upd_price_headers_flg;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_po_log
   * Description      : �����ϔ������׏��o��(C-9)
   ***********************************************************************************/
  PROCEDURE proc_put_po_log(
    iv_msg_no          IN  VARCHAR2,      -- ���b�Z�[�W�ԍ�
    iv_tkn_itm_no      IN  VARCHAR2,      -- �g�[�N���i��
    iv_tkn_h_no        IN  VARCHAR2,      -- �g�[�N�������ԍ�
    iv_tkn_m_no        IN  VARCHAR2,      -- �g�[�N����������
    iv_tkn_nonyu_date  IN  VARCHAR2,      -- �g�[�N���[����
    iv_po_no           IN  VARCHAR2,      -- �����ԍ�
    iv_po_l_no         IN  VARCHAR2,      -- ���הԍ�
    iv_item_no         IN  VARCHAR2,      -- �i�ڔԍ�
    iv_delivery_day    IN  VARCHAR2,      -- �[���ԍ�
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_po_log'; -- �v���O������
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
    lv_2space CONSTANT VARCHAR2(2) := '  ';   -- 2�X�y�[�X
--
    -- *** ���[�J���ϐ� ***
    lv_out_msg       VARCHAR2(5000);
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
    -- �������o��
    -- ===============================iv_delivery_day
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => iv_msg_no,
                    iv_token_name1  => iv_tkn_h_no,
                    iv_token_value1 => iv_po_no,
                    iv_token_name2  => iv_tkn_m_no,
                    iv_token_value2 => iv_po_l_no,
                    iv_token_name3  => iv_tkn_itm_no,
                    iv_token_value3 => iv_item_no,
                    iv_token_name4  => iv_tkn_nonyu_date,
                    iv_token_value4 => iv_delivery_day
                  ),1,5000);
--
    -- �������������׏��o�͂̏ꍇ�́A���b�Z�[�W�̓��ɃX�y�[�X�t�^
    IF (iv_msg_no = gv_msg_xxpo30030) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_2space || lv_out_msg);
--
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
    END IF;
--
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
  END proc_put_po_log;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_lot_data
   * Description      : ���b�g�݌ɒP���X�V(C-8)
   ***********************************************************************************/
  PROCEDURE proc_upd_lot_data(
    ir_po_data         IN  get_rec_type,  -- �������׏��
    ir_lot_data        IN  get_rec_lot,   -- ���b�g���
    in_cohi_unit_price IN  NUMBER,        -- ������P��
    in_total_amount    IN  NUMBER,        -- ���󍇌v
    in_depo_commission IN  NUMBER,        -- �a����K���z
    in_cane            IN  NUMBER,        -- ���ۋ��z
    in_cohi_rest       IN  NUMBER,        -- ��������z
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_lot_data'; -- �v���O������
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
    cv_api_name  CONSTANT VARCHAR2(100) := 'GMI_LOTUPDATE_PUB.UPDATE_LOT'; --���b�g�ύXAPI
    cv_jisei              VARCHAR2(1)   := '0';                            -- ����(0)
--
    -- *** ���[�J���ϐ� ***
    lv_result             VARCHAR2(1);                       -- API�֐��߂�l(�I���X�e�[�^�X)
    ln_msg_cnt            NUMBER;                            -- API�֐��߂�l(�X�^�b�N��)
    lv_msg                VARCHAR2(2000);                    -- API�֐��߂�l(���b�Z�[�W)
    l_lot_mst_rec         ic_lots_mst%ROWTYPE;               -- ���b�g�}�X�^���R�[�h�^�C�v
    l_lot_cpg_rec         ic_lots_cpg%ROWTYPE;               -- ���b�g���ԃ��R�[�h�^�C�v
    lv_out_msg            VARCHAR2(2000);                    -- ���O���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
   -- �����Ǘ��敪�������̏ꍇ�̂݃��b�g�X�V
   IF (ir_po_data.cost_manage_code = cv_jisei) AND (ir_lot_data.lot_id IS NOT NULL) THEN
--
     -- ���b�g�}�X�^���R�[�h�Z�b�g
     l_lot_mst_rec.item_id            := ir_po_data.item_id;           -- �i��ID
     l_lot_mst_rec.lot_id             := ir_lot_data.lot_id;           -- ���b�gID
     l_lot_mst_rec.lot_desc           := ir_lot_data.lot_desc;         -- ���b�g�E�v
     l_lot_mst_rec.qc_grade           := ir_lot_data.qc_grade;         -- �O���[�h
     l_lot_mst_rec.expaction_code     := ir_lot_data.expaction_code;   -- �����R�[�h
     l_lot_mst_rec.expaction_date     := ir_lot_data.expaction_date;   -- �������t
     l_lot_mst_rec.lot_created        := ir_lot_data.lot_created;      -- ���b�g�쐬��
     l_lot_mst_rec.expire_date        := ir_lot_data.expire_date;      -- ������
     l_lot_mst_rec.retest_date        := ir_lot_data.retest_date;      -- �ăe�X�g��
     l_lot_mst_rec.strength           := ir_lot_data.strength;         -- ���x
     l_lot_mst_rec.inactive_ind       := ir_lot_data.inactive_ind;     -- �L���t���O
     l_lot_mst_rec.shipvend_id        := ir_lot_data.shipvend_id;      -- �d����ID
     l_lot_mst_rec.vendor_lot_no      := ir_lot_data.vendor_lot_no;    -- �d�����b�gNO
     l_lot_mst_rec.attribute1         := ir_lot_data.create_day;       -- �����N����
     l_lot_mst_rec.attribute2         := ir_lot_data.attribute2;       -- �ŗL�L��
     l_lot_mst_rec.attribute3         := ir_lot_data.attribute3;       -- �ܖ�����
     l_lot_mst_rec.attribute4         := ir_lot_data.attribute4;       -- �[�����i����j
     l_lot_mst_rec.attribute5         := ir_lot_data.attribute5;       -- �[�����i�ŏI�j
     l_lot_mst_rec.attribute6         := ir_lot_data.attribute6;       -- �݌ɓ���
     l_lot_mst_rec.attribute7         := in_cohi_unit_price;           -- �݌ɒP��
     l_lot_mst_rec.attribute8         := ir_lot_data.attribute8;       -- �����
     l_lot_mst_rec.attribute9         := ir_lot_data.attribute9;       -- �d���`��
     l_lot_mst_rec.attribute10        := ir_lot_data.attribute10;      -- �����敪
     l_lot_mst_rec.attribute11        := ir_lot_data.attribute11;      -- �N�x
     l_lot_mst_rec.attribute12        := ir_lot_data.attribute12;      -- �Y�n
     l_lot_mst_rec.attribute13        := ir_lot_data.attribute13;      -- �^�C�v
     l_lot_mst_rec.attribute14        := ir_lot_data.attribute14;      -- �����N�P
     l_lot_mst_rec.attribute15        := ir_lot_data.attribute15;      -- �����N�Q
     l_lot_mst_rec.attribute16        := ir_lot_data.attribute16;      -- ���Y�`�[�敪
     l_lot_mst_rec.attribute17        := ir_lot_data.attribute17;      -- ���C����
     l_lot_mst_rec.attribute18        := ir_lot_data.attribute18;      -- �E�v
     l_lot_mst_rec.attribute19        := ir_lot_data.attribute19;      -- �����N�R
     l_lot_mst_rec.attribute20        := ir_lot_data.attribute20;      -- ���������H��
     l_lot_mst_rec.attribute21        := ir_lot_data.attribute21;      -- ���������b�g�ԍ�
     l_lot_mst_rec.attribute22        := ir_lot_data.attribute22;      -- �����˗�No
     l_lot_mst_rec.attribute23        := ir_lot_data.attribute23;      -- DFF23
     l_lot_mst_rec.attribute24        := ir_lot_data.attribute24;      -- DFF24
     l_lot_mst_rec.attribute25        := ir_lot_data.attribute25;      -- DFF25
     l_lot_mst_rec.attribute26        := ir_lot_data.attribute26;      -- DFF26
     l_lot_mst_rec.attribute27        := ir_lot_data.attribute27;      -- DFF27
     l_lot_mst_rec.attribute28        := ir_lot_data.attribute28;      -- DFF28
     l_lot_mst_rec.attribute29        := ir_lot_data.attribute29;      -- DFF29
     l_lot_mst_rec.attribute30        := ir_lot_data.attribute30;      -- DFF30
     l_lot_mst_rec.attribute_category := ir_lot_data.attribute_category;  -- DFF�J�e�S��
     l_lot_mst_rec.last_update_date   := gd_sysdate;                   -- �X�V��
     l_lot_mst_rec.last_updated_by    := gn_user_id;                   -- ���[�U�[ID
--
     -- ���b�g���ԃ��R�[�h�Z�b�g
     l_lot_cpg_rec.item_id            := ir_po_data.item_id;           -- �i��ID
     l_lot_cpg_rec.lot_id             := ir_lot_data.lot_id;           -- ���b�gID
     l_lot_cpg_rec.ic_hold_date       := ir_lot_data.ic_hold_date;     -- �ێ���
     l_lot_cpg_rec.last_update_date   := gd_sysdate;                   -- �X�V��
     l_lot_cpg_rec.last_updated_by    := gn_user_id;                   -- ���[�U�[ID
--
     -- ===============================
     -- ���b�g�P���ύXAPI���s
     -- ===============================
     GMI_LOTUPDATE_PUB.UPDATE_LOT(
       p_api_version          => gv_version,       -- �o�[�W����
       p_init_msg_list        => NULL,             -- ���b�Z�[�W�������t���O
       p_commit               => NULL,             -- �����m��t���O
       p_validation_level     => NULL,             -- ���؃��x��
       x_return_status        => lv_result,        -- �I���X�e�[�^�X
       x_msg_count            => ln_msg_cnt,       -- ���b�Z�[�W�X�^�b�N��
       x_msg_data             => lv_msg,           -- ���b�Z�[�W
       p_lot_rec              => l_lot_mst_rec,    -- ���b�g�}�X�^���R�[�h
       p_lot_cpg_rec          => l_lot_cpg_rec);   -- ���b�g���ԃ��R�[�h
--
      -- API�G���[
     IF (lv_result <> FND_API.G_RET_STS_SUCCESS) THEN
       lv_errmsg  := xxcmn_common_pkg.get_msg(
                       iv_application  => gv_xxcmn,
                       iv_name         => gv_msg_xxcmn10018,
                       iv_token_name1  => gv_tkn_api_name,
                       iv_token_value1 => cv_api_name);  -- ���b�Z�[�W�擾
        RAISE global_user_expt;
     END IF;
   END IF;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_upd_lot_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_po_data
   * Description      : �������ׂ̍X�V(C-7)
   ***********************************************************************************/
  PROCEDURE proc_upd_po_data(
    ir_po_data         IN  get_rec_type,  -- �������׏��
    in_total_amount    IN  NUMBER,        -- ���󍇌v
    in_cohi_unit_price IN  NUMBER,        -- ������P��
    in_depo_commission IN  NUMBER,        -- �a����K���z
    in_cane            IN  NUMBER,        -- ���ۋ��z
    in_cohi_rest       IN  NUMBER,        -- ��������z
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_po_data'; -- �v���O������
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
    cv_api_name    CONSTANT VARCHAR2(100) := 'PO_CHANGE_API1_S.UPDATE_PO'; --�����ύXAPI
--
    -- *** ���[�J���ϐ� ***
    ln_result             NUMBER;                            -- API�֐��߂�l
    ltbl_api_errors       PO_API_ERRORS_REC_TYPE;            -- API�G���[�߂�l
    lv_out_msg            VARCHAR2(2000);                    -- ���O���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
    -- ===============================
    -- �����ύXAPI���s
    -- ===============================
    ln_result := PO_CHANGE_API1_S.UPDATE_PO(
                   x_po_number               => ir_po_data.po_no,                 -- �����ԍ�
                   x_release_number          => NULL,                             -- �����[�X�ԍ�
                   x_revision_number         => ir_po_data.revision_num,          -- �o�[�W�����ԍ�
                   x_line_number             => ir_po_data.po_l_no,               -- �������הԍ�
                   x_shipment_number         => NULL,                             -- �[�����הԍ�
                   new_quantity              => NULL,                             -- ����
                   new_price                 => in_cohi_unit_price,               -- ���i
                   new_promised_date         => NULL,                             -- �[��
                   launch_approvals_flag     => gv_y,                             -- ���F�X�e�[�^�X
                   update_source             => NULL,                             -- �A�b�v�f�[�g
                   version                   => gv_version,                       -- �o�[�W����
                   x_override_date           => NULL,                             -- �㏑���t
                   x_api_errors              => ltbl_api_errors,                  -- �G���[���
                   p_buyer_name              => NULL);                            -- �S����
--
    -- API�G���[
    IF (ln_result = gn_zero) THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxcmn,
                      iv_name         => gv_msg_xxcmn10018,
                      iv_token_name1  => gv_tkn_api_name,
                      iv_token_value1 => cv_api_name);  -- ���b�Z�[�W�擾
      RAISE global_user_expt;
    END IF;
--
    -- ===============================
    -- �������ׂ̍X�V
    -- ===============================
    UPDATE po_lines_all pla                                                -- ��������
    SET    pla.attribute8             = in_total_amount                    -- �d���艿(DFF)
          ,pla.last_updated_by        = gn_user_id                         -- �ŏI�X�V��
          ,pla.last_update_date       = gd_sysdate                         -- �ŏI�X�V��
          ,pla.last_update_login      = gn_login_id                        -- �ŏI�X�V���O�C��
          ,pla.request_id             = gn_request_id                      -- �v��ID
          ,pla.program_application_id = gn_appl_id                         -- ���ع����ID
          ,pla.program_id             = gn_program_id                      -- �v���O����ID
          ,pla.program_update_date    = gd_sysdate                         -- �v���O�����X�V��
    WHERE pla.po_line_id              = ir_po_data.po_line_id              -- ��������ID
    ;
--
    -- ===============================
    -- �����[�����ׂ̍X�V
    -- ===============================
    -- �a����K���z�A���ۋ��z�A��������z�̂����ꂩ�̌v�Z���s��ꂽ�ꍇ�̂ݍX�V
    IF (gn_depo_flg = 1) OR (gn_cane_flg = 1) THEN
--
      UPDATE po_line_locations_all plla                                       -- �����[������
      SET    plla.attribute2             = in_cohi_unit_price                 -- ������P��
            ,plla.attribute5             = CASE
                                             WHEN gn_depo_flg = 0 THEN plla.attribute5
                                             ELSE TO_CHAR(in_depo_commission) -- �a����K���z
                                           END
            ,plla.attribute8             = CASE
                                             WHEN gn_cane_flg = 0 THEN  plla.attribute8
                                             ELSE TO_CHAR(in_cane)            -- ���ۋ��z
                                           END
            ,plla.attribute9             = in_cohi_rest                       -- ��������z
            ,plla.last_updated_by        = gn_user_id                         -- �ŏI�X�V��
            ,plla.last_update_date       = gd_sysdate                         -- �ŏI�X�V��
            ,plla.last_update_login      = gn_login_id                        -- �ŏI�X�V���O�C��
            ,plla.request_id             = gn_request_id                      -- �v��ID
            ,plla.program_application_id = gn_appl_id                         -- ���ع����ID
            ,plla.program_id             = gn_program_id                      -- �v���O����ID
            ,plla.program_update_date    = gd_sysdate                         -- �v���O�����X�V��
      WHERE plla.line_location_id        = ir_po_data.line_location_id        -- �����[������ID
      ;
--
    END IF;
--
    -- �X�V����
    gn_normal_cnt := gn_normal_cnt + 1;
--
--
  EXCEPTION
--
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_upd_po_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_calc_data
   * Description      : �v�Z����(C-6)
   ***********************************************************************************/
  PROCEDURE proc_calc_data(
    ir_po_data         IN  get_rec_type,  -- �������׏��
    in_total_amount    IN  NUMBER,        -- ���󍇌v
    on_cohi_unit_price OUT NUMBER,        -- ������P��
    on_depo_commission OUT NUMBER,        -- �a����K���z
    on_cane            OUT NUMBER,        -- ���ۋ��z
    on_cohi_rest       OUT NUMBER,        -- ��������z
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_calc_data'; -- �v���O������
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
    ln_quantity               NUMBER DEFAULT 0;            -- ����
    ln_kona                   NUMBER DEFAULT 0;            -- �����z
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
    -- ===============================
    -- ���ʂ̎Z�o
    -- ===============================
    IF (ir_po_data.status > gv_po_stats) THEN
      ln_quantity := TRUNC(TO_NUMBER(ir_po_data.po_quantity));
    ELSE
      ln_quantity := TRUNC(TO_NUMBER(ir_po_data.rcv_quantity));
    END IF;
--
    -- �i�ڂ��h�����N���i�̏ꍇ(�P�ʂƔ����P�ʂ��قȂ�ꍇ)�� ���� = ���� * �P�[�X����
    IF (ir_po_data.base_uom <> ir_po_data.po_uom) THEN
      ln_quantity := TRUNC(ln_quantity * TO_NUMBER(ir_po_data.num_of_cases));
    END IF;
--
    -- ===============================
    -- ������P���̌v�Z
    -- ===============================
    on_cohi_unit_price := TRUNC(in_total_amount * (gn_100 - TO_NUMBER(ir_po_data.powde_lead))
                          / gn_100);
--
    -- ===============================
    -- �a����K���z�̌v�Z
    -- ===============================
    IF (ir_po_data.commission_type = gv_rate)
      AND  (ir_po_data.commission IS NOT NULL) THEN
      on_depo_commission := TRUNC(ln_quantity * in_total_amount *
                            ir_po_data.commission / gn_100);
      gn_depo_flg := 1;
    END IF;
--
    -- ===============================
    -- ���ۋ��z�̌v�Z
    -- ===============================
    IF ((ir_po_data.assessment_type = gv_rate)
      AND (ir_po_data.assessment IS NOT NULL)) THEN
      ln_kona := in_total_amount * ln_quantity * TO_NUMBER(ir_po_data.powde_lead) / gn_100;
      on_cane := TRUNC((in_total_amount * ln_quantity - ln_kona)
                       * TO_NUMBER(ir_po_data.assessment) / gn_100);
      gn_cane_flg := 1;
    END IF;
--
    -- ===============================
    -- ��������z�̌v�Z
    -- ===============================
    on_cohi_rest := TRUNC(on_cohi_unit_price * ln_quantity);
--
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
  END proc_calc_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_unit_price
   * Description      : �d���P���f�[�^�擾(C-5)
   ***********************************************************************************/
  PROCEDURE proc_get_unit_price(
    iv_date_type       IN     VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    ir_po_data         IN     get_rec_type,  -- �������׏��
    ir_lot_data        IN     get_rec_lot,   -- ���b�g���
    on_price_header_id OUT    NUMBER,        -- �w�b�_ID
    on_total_amount    OUT    NUMBER,        -- ���󍇌v
    ov_errbuf          OUT    VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT    VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT    VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_unit_price'; -- �v���O������
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
    lc_vend              CONSTANT VARCHAR2(1) := '1';             -- �d��
--
    -- *** ���[�J���ϐ� ***
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
    ld_active            DATE;                                    -- ���t
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
    -- ===============================
    -- ���t�̔���
    -- ===============================
    IF (iv_date_type = gv_mgc_day) THEN
    -- ���t�^�C�v��������(1)�̏ꍇ�͐����N�������Ώ�
      ld_active := FND_DATE.STRING_TO_DATE(ir_lot_data.create_day,gv_format_yyyymmdd);
    ELSE
    -- ���t�^�C�v���[����(2)�̏ꍇ�͔[���N�������Ώ�
      ld_active := FND_DATE.STRING_TO_DATE(ir_po_data.delivery_day,gv_format_yyyymmdd);
    END IF;
--
    BEGIN
--
      -- ===============================
      -- �d��/�W���P���w�b�_�̎擾
      -- ===============================
      lv_sql :=
        '   SELECT xph.price_header_id price_header_id,'            -- �w�b�_ID
        || '       xph.total_amount    total_amount'                -- ���󍇌v
        || '  FROM xxpo_price_headers xph'                          -- �d��/�W���P���w�b�_
        || ' WHERE xph.item_id             = :item_id'              -- �i��ID
        || '   AND xph.price_type          = :type'                 -- �}�X�^�敪
        || '   AND xph.vendor_id           = :vendor_id'            -- �����ID
        || '   AND (xph.start_date_active <= :start_date_active'    -- �K�p�J�n��
        || '   AND xph.end_date_active    >= :end_date_active)'     -- �K�p�I����
        || '   AND xph.record_change_flg   = :change_y'             -- �ύX�����t���O
        || '   AND xph.factory_code        = :factory_code'         -- �H��R�[�h
        || '   AND xph.futai_code          = :futai_code';          -- �t�уR�[�h
--
      -- �����敪���x��(3)�̏ꍇ�͎x����R�[�h�������ɂ���
      IF (ir_po_data.direct_sending_type = gv_provision) THEN
--
        lv_sql := lv_sql
          || '   AND (xph.supply_to_code      = :supply_to_code'    -- �x����R�[�h
          || '        OR xph.supply_to_code   IS NULL)'
          || ' FOR UPDATE NOWAIT';
--
        EXECUTE IMMEDIATE lv_sql
                     INTO on_price_header_id,
                          on_total_amount
          USING ir_po_data.item_id,
                lc_vend,
                ir_po_data.vendor_id,
                ld_active,
                ld_active,
                gv_y,
                ir_po_data.fact_code,
                ir_po_data.accompany_code,
                ir_po_data.delivery_code;
      ELSE
--
        lv_sql := lv_sql
          || ' FOR UPDATE NOWAIT';
--
        EXECUTE IMMEDIATE lv_sql
                     INTO on_price_header_id,
                          on_total_amount
          USING ir_po_data.item_id,
                lc_vend,
                ir_po_data.vendor_id,
                ld_active,
                ld_active,
                gv_y,
                ir_po_data.fact_code,
                ir_po_data.accompany_code;
      END IF;
--
    EXCEPTION
--
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_price_headers ),1,5000);
        RAISE global_user_expt;
--
      --*** �f�[�^�Ȃ��擾�G���[ ***
      WHEN NO_DATA_FOUND THEN
        gn_warn_cnt := gn_warn_cnt + 1;
--
        -- ===============================
        -- C-12.�������������׏��o��
        -- ===============================
        proc_put_po_log(
          iv_msg_no         =>  gv_msg_xxpo30030,             -- ���b�Z�[�W�ԍ�
          iv_tkn_itm_no     =>  gv_tkn_ng_item_no,           -- �g�[�N���i��
          iv_tkn_h_no       =>  gv_tkn_ng_h_no,              -- �g�[�N�������ԍ�
          iv_tkn_m_no       =>  gv_tkn_ng_m_no,              -- �g�[�N����������
          iv_tkn_nonyu_date =>  gv_tkn_ng_nonyu_date,        -- �g�[�N���[����
          iv_po_no          =>  ir_po_data.po_no,            -- �����ԍ�
          iv_po_l_no        =>  ir_po_data.po_l_no,          -- ���הԍ�
          iv_item_no        =>  ir_po_data.item_no,          -- �i�ڔԍ�
          iv_delivery_day   =>  ir_po_data.delivery_day,     -- �[����
          ov_errbuf         =>  lv_errbuf,                   -- �G���[�E���b�Z�[�W
          ov_retcode        =>  lv_retcode,                  -- ���^�[���E�R�[�h
          ov_errmsg         =>  lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[�̏ꍇ
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_user_expt;
        END IF;
    END;
--
  EXCEPTION
--
    --*** ���[�U�[��`��O ***
    WHEN global_user_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_get_unit_price;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_lot_data
   * Description      : ���b�g�f�[�^�擾
   ***********************************************************************************/
  PROCEDURE proc_get_lot_data(
    iv_date_type       IN     VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN     VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN     VARCHAR2,      -- ���ԏI����(YYYY/MM/DD)
    ir_po_data         IN     get_rec_type,  -- �������׏��
    or_lot_data        OUT    get_rec_lot,   -- ���b�g���
    ov_errbuf          OUT    VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT    VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT    VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_lot_data'; -- �v���O������
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
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
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
--
    BEGIN
--
      -- ===============================
      -- ���b�g�}�X�^���̎擾
      -- ===============================
      lv_sql :=
        '    SELECT ilm.lot_id             AS  lot_id'                -- ���b�gID
        || '       ,ilm.lot_desc           AS  lot_desc'              -- ���b�g�E�v
        || '       ,ilm.qc_grade           AS  qc_grade'              -- �O���[�h
        || '       ,ilm.expaction_code     AS  expaction_code'        -- �����R�[�h
        || '       ,ilm.expaction_date     AS  expaction_date'        -- �������t
        || '       ,ilm.lot_created        AS  lot_created'           -- ���b�g�쐬��
        || '       ,ilm.expire_date        AS  expire_date'           -- ������
        || '       ,ilm.retest_date        AS  retest_date'           -- �ăe�X�g��
        || '       ,ilm.strength           AS  strength'              -- ���x
        || '       ,ilm.inactive_ind       AS  inactive_ind'          -- �L���t���O
        || '       ,ilm.shipvend_id        AS  shipvend_id'           -- �d����ID
        || '       ,ilm.vendor_lot_no      AS  vendor_lot_no'         -- �d�����b�gNO
        || '       ,ilm.attribute1         AS  create_day'            -- �����N����
        || '       ,ilm.attribute2         AS  attribute2'            -- �ŗL�L��
        || '       ,ilm.attribute3         AS  attribute3'            -- �ܖ�����
        || '       ,ilm.attribute4         AS  attribute4'            -- �[�����i����j
        || '       ,ilm.attribute5         AS  attribute5'            -- �[�����i�ŏI�j
        || '       ,ilm.attribute6         AS  attribute6'            -- �݌ɓ���
        || '       ,ilm.attribute7         AS  attribute7'            -- �݌ɒP��
        || '       ,ilm.attribute8         AS  attribute8'            -- �����
        || '       ,ilm.attribute9         AS  attribute9'            -- �d���`��
        || '       ,ilm.attribute10        AS  attribute10'           -- �����敪
        || '       ,ilm.attribute11        AS  attribute11'           -- �N�x
        || '       ,ilm.attribute12        AS  attribute12'           -- �Y�n
        || '       ,ilm.attribute13        AS  attribute13'           -- �^�C�v
        || '       ,ilm.attribute14        AS  attribute14'           -- �����N�P
        || '       ,ilm.attribute15        AS  attribute15'           -- �����N�Q
        || '       ,ilm.attribute16        AS  attribute16'           -- ���Y�`�[�敪
        || '       ,ilm.attribute17        AS  attribute17'           -- ���C����
        || '       ,ilm.attribute18        AS  attribute18'           -- �E�v
        || '       ,ilm.attribute19        AS  attribute19'           -- �����N�R
        || '       ,ilm.attribute20        AS  attribute20'           -- ���������H��
        || '       ,ilm.attribute21        AS  attribute21'           -- �������������b�g�ԍ�
        || '       ,ilm.attribute22        AS  attribute22'           -- �����˗�No
        || '       ,ilm.attribute23        AS  attribute23'           -- DFF23
        || '       ,ilm.attribute24        AS  attribute24'           -- DFF24
        || '       ,ilm.attribute25        AS  attribute25'           -- DFF25
        || '       ,ilm.attribute26        AS  attribute26'           -- DFF26
        || '       ,ilm.attribute27        AS  attribute27'           -- DFF27
        || '       ,ilm.attribute28        AS  attribute28'           -- DFF28
        || '       ,ilm.attribute29        AS  attribute29'           -- DFF29
        || '       ,ilm.attribute30        AS  attribute30'           -- DFF30
        || '       ,ilm.attribute_category AS  attribute_category'    -- DFF�J�e�S��
        || '       ,ilc.ic_hold_date       AS  ic_hold_date'          -- �ێ���
        || ' FROM ic_lots_mst           ilm '                         -- OPM���b�g�}�X�^
        || '     ,ic_lots_cpg           ilc ';                        -- OPM���b�g�ێ�����
--
    -- ���t�^�C�v����SQL����
    IF (iv_date_type = gv_mgc_day) THEN
      -- ���t�^�C�v���������̏ꍇ
      lv_sql := lv_sql || ' WHERE ilm.attribute1 BETWEEN :start_date AND :end_date' --������
                       || ' AND   ilm.item_id    = :item_id'     -- �i��ID
                       || ' AND   ilm.lot_no     = :lot_no'      -- ���b�gNO
                       || ' AND   ilc.item_id(+) = ilm.item_id'  -- �i��ID
                       || ' AND   ilc.lot_id(+)  = ilm.lot_id'   -- ���b�gID
                       || ' FOR UPDATE NOWAIT';
--
       EXECUTE IMMEDIATE lv_sql
                    INTO or_lot_data.lot_id,
                         or_lot_data.lot_desc,
                         or_lot_data.qc_grade,
                         or_lot_data.expaction_code,
                         or_lot_data.expaction_date,
                         or_lot_data.lot_created,
                         or_lot_data.expire_date,
                         or_lot_data.retest_date,
                         or_lot_data.strength,
                         or_lot_data.inactive_ind,
                         or_lot_data.shipvend_id,
                         or_lot_data.vendor_lot_no,
                         or_lot_data.create_day,
                         or_lot_data.attribute2,
                         or_lot_data.attribute3,
                         or_lot_data.attribute4,
                         or_lot_data.attribute5,
                         or_lot_data.attribute6,
                         or_lot_data.attribute7,
                         or_lot_data.attribute8,
                         or_lot_data.attribute9,
                         or_lot_data.attribute10,
                         or_lot_data.attribute11,
                         or_lot_data.attribute12,
                         or_lot_data.attribute13,
                         or_lot_data.attribute14,
                         or_lot_data.attribute15,
                         or_lot_data.attribute16,
                         or_lot_data.attribute17,
                         or_lot_data.attribute18,
                         or_lot_data.attribute19,
                         or_lot_data.attribute20,
                         or_lot_data.attribute21,
                         or_lot_data.attribute22,
                         or_lot_data.attribute23,
                         or_lot_data.attribute24,
                         or_lot_data.attribute25,
                         or_lot_data.attribute26,
                         or_lot_data.attribute27,
                         or_lot_data.attribute28,
                         or_lot_data.attribute29,
                         or_lot_data.attribute30,
                         or_lot_data.attribute_category,
                         or_lot_data.ic_hold_date
         USING iv_start_date,
               iv_end_date,
               ir_po_data.item_id,
               ir_po_data.lot_no;
--
    ELSE
      lv_sql := lv_sql || ' WHERE ilm.item_id(+) = :item_id'     -- �i��ID
                       || ' AND   ilm.lot_no(+)  = :lot_no'      -- ���b�gNO
                       || ' AND   ilc.item_id(+) = ilm.item_id'  -- �i��ID
                       || ' AND   ilc.lot_id(+)  = ilm.lot_id'   -- ���b�gID
                       || ' FOR UPDATE NOWAIT';
--
       EXECUTE IMMEDIATE lv_sql
                    INTO or_lot_data.lot_id,
                         or_lot_data.lot_desc,
                         or_lot_data.qc_grade,
                         or_lot_data.expaction_code,
                         or_lot_data.expaction_date,
                         or_lot_data.lot_created,
                         or_lot_data.expire_date,
                         or_lot_data.retest_date,
                         or_lot_data.strength,
                         or_lot_data.inactive_ind,
                         or_lot_data.shipvend_id,
                         or_lot_data.vendor_lot_no,
                         or_lot_data.create_day,
                         or_lot_data.attribute2,
                         or_lot_data.attribute3,
                         or_lot_data.attribute4,
                         or_lot_data.attribute5,
                         or_lot_data.attribute6,
                         or_lot_data.attribute7,
                         or_lot_data.attribute8,
                         or_lot_data.attribute9,
                         or_lot_data.attribute10,
                         or_lot_data.attribute11,
                         or_lot_data.attribute12,
                         or_lot_data.attribute13,
                         or_lot_data.attribute14,
                         or_lot_data.attribute15,
                         or_lot_data.attribute16,
                         or_lot_data.attribute17,
                         or_lot_data.attribute18,
                         or_lot_data.attribute19,
                         or_lot_data.attribute20,
                         or_lot_data.attribute21,
                         or_lot_data.attribute22,
                         or_lot_data.attribute23,
                         or_lot_data.attribute24,
                         or_lot_data.attribute25,
                         or_lot_data.attribute26,
                         or_lot_data.attribute27,
                         or_lot_data.attribute28,
                         or_lot_data.attribute29,
                         or_lot_data.attribute30,
                         or_lot_data.attribute_category,
                         or_lot_data.ic_hold_date
         USING ir_po_data.item_id,
               ir_po_data.lot_no;
    END IF;
--
    EXCEPTION
--
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_po_line     || gv_msg_comma
                                        || gv_po_location || gv_msg_comma
                                        || gv_lot_mst ),1,5000);
        RAISE global_user_expt;
--
    END;
--
--
  EXCEPTION
--
    --*** ���[�U�[��`��O ***
    WHEN global_user_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_get_lot_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_get_po_data
   * Description      : �������׃f�[�^�擾(C-3,C-4)
   ***********************************************************************************/
  PROCEDURE proc_get_po_data(
    iv_date_type       IN  VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN  VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- ���ԏI����(YYYY/MM/DD)
    iv_item_type_name  IN  VARCHAR2,      -- �i�ڋ敪��
    iv_goods_type_name IN  VARCHAR2,      -- ���i�敪��
    ir_item            IN  g_rec_item,    -- �i�ڏ��
    ir_vender          IN  g_rec_vender,  -- �������
    ot_data_rec        OUT get_po_tbl,    -- �������
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_po_data'; -- �v���O������
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
    lv_sql               VARCHAR2(32767) DEFAULT NULL;            -- SQL
--
    -- *** ���[�J���E�J�[�\�� ***
    -- <�J�[�\����>
    TYPE cursor_type IS REF CURSOR;
    data_cur cursor_type;
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
--
--
    -- ===============================
    -- SQL���̎擾
    -- ===============================
    lv_sql := func_create_sql(
                iv_date_type       => iv_date_type,       -- ���t�^�C�v(1:������ 2:�[����)
                iv_start_date      => iv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
                iv_end_date        => iv_end_date,        -- ���ԏI����(YYYY/MM/DD)
                iv_goods_type_name => iv_goods_type_name, -- ���i�敪��
                iv_item_type_name  => iv_item_type_name,  -- �i�ڋ敪��
                ir_item            => ir_item,            -- �i��ID1
                ir_vender          => ir_vender);         -- �����ID3
--
    BEGIN
--
    -- �J�[�\���I�[�v��
      OPEN data_cur FOR lv_sql;
      -- �o���N�t�F�b�`
      FETCH data_cur BULK COLLECT INTO ot_data_rec ;
--
      IF (ot_data_rec.COUNT = 0) THEN
        -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�͌x���I��
        -- �擾�f�[�^���O���̏ꍇ�G���[
        ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10093
                      ),1,5000);
        ov_retcode := gv_status_warn;
      END IF;
      -- �J�[�\���N���[�Y
      CLOSE data_cur;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxcmn,
                        iv_name         => gv_msg_xxcmn10019,
                        iv_token_name1  => gv_tkn_table,
                        iv_token_value1 => gv_po_line     || gv_msg_comma
                                        || gv_po_location || gv_msg_comma
                                        || gv_lot_mst ),1,5000);
        RAISE global_user_expt;
    END;
--
--
  EXCEPTION
--
    --*** ���[�U�[��`��O ***
    WHEN global_user_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( data_cur%ISOPEN ) THEN
        CLOSE data_cur ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_get_po_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_check_param
   * Description      : �p�����[�^�`�F�b�N(C-2)
   ***********************************************************************************/
  PROCEDURE proc_check_param(
    iv_date_type       IN     VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN     VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD HH24:MI:SS)
    iv_end_date        IN     VARCHAR2,      -- ���ԏI����(YYYY/MM/DD HH24:MI:SS)
    iv_commodity_type  IN     VARCHAR2,      -- ���i�敪
    iv_item_type       IN     VARCHAR2,      -- �i�ڋ敪
    ior_item           IN OUT g_rec_item,    -- �i�ڏ��
    ior_vender         IN OUT g_rec_vender,  -- �������
    ov_start_date      OUT     VARCHAR2,     -- ���ԊJ�n��(YYYY/MM/DD)
    ov_end_date        OUT     VARCHAR2,     -- ���ԏI����(YYYY/MM/DD)
    ov_item_type_name  OUT    VARCHAR2,      -- �i�ڋ敪��
    ov_goods_type_name OUT    VARCHAR2,      -- ���i�敪��
    ov_errbuf          OUT    VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT    VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT    VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check_param'; -- �v���O������
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
    lv_lookup_code          xxcmn_lookup_values_v.lookup_code%TYPE; -- ���b�N�A�b�v�R�[�h
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
    -- ==============================================================
    -- ���t�^�C�v�����͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_date_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_date_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ����(�J�n)�����͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_start_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_start_date
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ����(�I��)�����͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_end_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_end_date
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ���i�敪�����͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_commodity_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_commodity_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- �i�ڋ敪�����͂���Ă��邩�`�F�b�N���܂��B
    -- ==============================================================
    IF (iv_item_type IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10102,
                      iv_token_name1  => gv_tkn_param_name,
                      iv_token_value1 => gv_tkn_val_item_type
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ���t�^�C�v���N�C�b�N�R�[�h���ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT lookup_code lookup_code
      INTO   lv_lookup_code
      FROM   xxcmn_lookup_values_v xlvv             -- �N�C�b�N�R�[�h���VIEW
      WHERE  lookup_type = gv_xxcmn_date_type
      AND    lookup_code = iv_date_type
      AND    ROWNUM      = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_date_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_date_type
                    ),1,5000);
        RAISE global_user_expt;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- ���i�敪���i�ڃJ�e�S�����ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT xcv.description description
      INTO   ov_goods_type_name
      FROM   xxcmn_categories_v xcv             -- �i�ڃJ�e�S�����VIEW
      WHERE  xcv.category_set_name = gv_cat_set_goods_class
      AND    xcv.segment1          = iv_commodity_type
      AND    ROWNUM                = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_commodity_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_commodity_type
                    ),1,5000);
        RAISE global_user_expt;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- �i�ڋ敪���J�e�S�����ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    BEGIN
      SELECT xcv.description description
      INTO   ov_item_type_name
      FROM   xxcmn_categories_v xcv             -- �i�ڃJ�e�S�����VIEW
      WHERE  xcv.category_set_name = gv_cat_set_item_class
      AND    xcv.segment1          = iv_item_type
      AND    ROWNUM                = 1;
    EXCEPTION
    -- �f�[�^���Ȃ��ꍇ�̓G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_item_type,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => iv_item_type
                    ),1,5000);
        RAISE global_user_expt;
      -- ���̑��G���[
      WHEN OTHERS THEN
        RAISE;
    END;
--
    -- ==============================================================
    -- �i�ڂ�OPM�i�ڃ}�X�^�ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    <<item_chek_loop>>
    FOR i IN 1..ior_item.item_no.COUNT LOOP
--
      ior_item.item_id(i) := func_chk_item_no(
                       iv_item_no => ior_item.item_no(i));
      IF (ior_item.item_id(i) IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_item,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => ior_item.item_no(i)
                    ),1,5000);
        RAISE global_user_expt;
      END IF;
--
    END LOOP item_chek_loop;
--
    -- ==============================================================
    -- �����R�[�h���d����}�X�^�ɑ��݂��邩�`�F�b�N
    -- ==============================================================
    <<vender_chek_loop>>
    FOR i IN 1..ior_vender.vender_code.COUNT LOOP
      ior_vender.vender_id(i) := func_chk_customer(
                           iv_customer_code => ior_vender.vender_code(i));
      IF (ior_vender.vender_id(i) IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10103,
                        iv_token_name1  => gv_tkn_param_name,
                        iv_token_value1 => gv_tkn_val_customer,
                        iv_token_name2  => gv_tkn_param_value,
                        iv_token_value2 => ior_vender.vender_code(i)
                    ),1,5000);
        RAISE global_user_expt;
      END IF;
    END LOOP vender_chek_loop;
--
    -- ==============================================================
    -- ���ԊJ�n�����N�����Ƃ��Đ��������`�F�b�N
    -- ==============================================================
    ov_start_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_start_date,gv_dt_format),
                            gv_format_yyyymmdd);
    IF (ov_start_date IS NULL) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10104,
                      iv_token_name1  => gv_tkn_param_value,
                      iv_token_value1 => iv_start_date
                  ),1,5000);
      RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ���ԏI�������N�����Ƃ��Đ��������`�F�b�N
    -- ==============================================================
    ov_end_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_end_date, gv_dt_format),
                            gv_format_yyyymmdd);
    IF (ov_end_date IS NULL) THEN
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                        iv_application  => gv_xxpo,
                        iv_name         => gv_msg_xxpo10104,
                        iv_token_name1  => gv_tkn_param_value,
                        iv_token_value1 => iv_end_date
                    ),1,5000);
        RAISE global_user_expt;
    END IF;
--
    -- ==============================================================
    -- ����(�J�n) �� ����(�I��) �ɂȂ��Ă��邩�`�F�b�N
    -- ==============================================================
    IF (iv_start_date > iv_end_date) THEN
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application  => gv_xxpo,
                      iv_name         => gv_msg_xxpo10105
                    ),1,5000);
      RAISE global_user_expt;
    END IF;
--
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END proc_check_param;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_put_parameter_log
   * Description      : �O����(���̓p�����[�^���O�o�͏���)(C-1)
   ***********************************************************************************/
  PROCEDURE proc_put_parameter_log(
    iv_date_type       IN  VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN  VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- ���ԏI����(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      -- ���i�敪
    iv_item_type       IN  VARCHAR2,      -- �i�ڋ敪
    iv_item_code1      IN  VARCHAR2,      -- �i�ڃR�[�h1
    iv_item_code2      IN  VARCHAR2,      -- �i�ڃR�[�h2
    iv_item_code3      IN  VARCHAR2,      -- �i�ڃR�[�h3
    iv_customer_code1  IN  VARCHAR2,      -- �����R�[�h1
    iv_customer_code2  IN  VARCHAR2,      -- �����R�[�h2
    iv_customer_code3  IN  VARCHAR2,      -- �����R�[�h3
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_put_parameter_log'; -- �v���O������
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
    lv_out_msg       VARCHAR2(5000);
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
    -- �p�����[�^�[���o��
    -- ===============================
    lv_out_msg := SUBSTRB(xxcmn_common_pkg.get_msg(
                    iv_application  => gv_xxpo,
                    iv_name         => gv_msg_xxpo30036,
                    iv_token_name1  => gv_tkn_data_type,
                    iv_token_value1 => iv_date_type,
                    iv_token_name2  => gv_tkn_date_from,
                    iv_token_value2 => iv_start_date,
                    iv_token_name3  => gv_tkn_data_to,
                    iv_token_value3 => iv_end_date,
                    iv_token_name4  => gv_tkn_goods_category,
                    iv_token_value4 => iv_commodity_type,
                    iv_token_name5  => gv_tkn_item_category,
                    iv_token_value5 => iv_item_type,
                    iv_token_name6  => gv_tkn_item_no,
                    iv_token_value6 => iv_item_code1     || gv_msg_comma ||
                                       iv_item_code2     || gv_msg_comma ||
                                       iv_item_code3     || gv_msg_comma,
                    iv_token_name7  => gv_tkn_vendor_code,
                    iv_token_value7 => iv_customer_code1 || gv_msg_comma ||
                                       iv_customer_code2 || gv_msg_comma ||
                                       iv_customer_code3 || gv_msg_comma
                  ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
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
  END proc_put_parameter_log;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_type       IN  VARCHAR2,      -- ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN  VARCHAR2,      -- ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      -- ���ԏI����(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      -- ���i�敪
    iv_item_type       IN  VARCHAR2,      -- �i�ڋ敪
    iv_item_code1      IN  VARCHAR2,      -- �i�ڃR�[�h1
    iv_item_code2      IN  VARCHAR2,      -- �i�ڃR�[�h2
    iv_item_code3      IN  VARCHAR2,      -- �i�ڃR�[�h3
    iv_customer_code1  IN  VARCHAR2,      -- �����R�[�h1
    iv_customer_code2  IN  VARCHAR2,      -- �����R�[�h2
    iv_customer_code3  IN  VARCHAR2,      -- �����R�[�h3
    ov_errbuf          OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_request_count NUMBER;    -- �v��ID�J�E���g
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_start_date      ic_lots_mst.attribute1%TYPE DEFAULT NULL;               -- �J�n��
    lv_end_date        ic_lots_mst.attribute1%TYPE DEFAULT NULL;               -- �I����
    lv_p_item_type     fnd_profile_option_values.profile_option_value%TYPE;    -- �i�ڋ敪
    lv_p_goods_type    fnd_profile_option_values.profile_option_value%TYPE;    -- ���i�敪
    lv_item_type_name  xxcmn_categories_v.description%TYPE;                    -- �i�ڋ敪��
    lv_goods_type_name xxcmn_categories_v.description%TYPE;                    -- ���i�敪��
    ln_item_id1        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- �i��ID1
    ln_item_id2        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- �i��ID2
    ln_item_id3        mtl_system_items_b.inventory_item_id%TYPE DEFAULT NULL; -- �i��ID3
    ln_vendor_id1      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- �d����ID1
    ln_vendor_id2      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- �d����ID2
    ln_vendor_id3      po_vendors.vendor_id%TYPE DEFAULT NULL;                 -- �d����ID3
    ln_price_header_id xxpo_price_headers.price_header_id%TYPE DEFAULT NULL;   -- �w�b�_ID
    ln_total_amount    xxpo_price_headers.total_amount%TYPE DEFAULT NULL;      -- ���󍇌v
    ln_cohi_unit_price NUMBER DEFAULT 0;                                       -- ������P��
    ln_depo_commission NUMBER DEFAULT 0;                                       -- �a����K���z
    ln_cane            NUMBER DEFAULT 0;                                       -- ���ۋ��z
    ln_cohi_rest       NUMBER DEFAULT 0;                                       -- ��������z
    ln_item_cnt        NUMBER DEFAULT 0;                                       -- ����
    ln_vender_cnt      NUMBER DEFAULT 0;                                       -- ����
    ln_p_h_cnt         NUMBER DEFAULT 1;                                       -- ����
    lt_p_header_id     gt_p_header_id;                                         -- �d���P��ID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_data_rec  get_po_tbl;
    l_rec_item   g_rec_item;
    l_rec_vender g_rec_vender;
    lr_lot_data  get_rec_lot;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- C-1.�O����(���̓p�����[�^���O�o�͏���)
    -- ===============================
    proc_put_parameter_log(
      iv_date_type       => iv_date_type,       -- ���t�^�C�v(1:������ 2:�[����)
      iv_start_date      => iv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- ���ԏI����(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- ���i�敪
      iv_item_type       => iv_item_type,       -- �i�ڋ敪
      iv_item_code1      => iv_item_code1,      -- �i�ڃR�[�h1
      iv_item_code2      => iv_item_code2,      -- �i�ڃR�[�h2
      iv_item_code3      => iv_item_code3,      -- �i�ڃR�[�h3
      iv_customer_code1  => iv_customer_code1,  -- �����R�[�h1
      iv_customer_code2  => iv_customer_code2,  -- �����R�[�h2
      iv_customer_code3  => iv_customer_code3,  -- �����R�[�h3
      ov_errbuf          => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode         => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg          => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ���̓o�����[�^�i�[
--
    -- �i�ڂP
    IF (TRIM(iv_item_code1) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code1;
    END IF;
    -- �i�ڂQ
    IF (TRIM(iv_item_code2) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code2;
    END IF;
    -- �i�ڂR
    IF (TRIM(iv_item_code3) IS NOT NULL) THEN
      ln_item_cnt := l_rec_item.item_no.COUNT + 1;
      l_rec_item.item_no(ln_item_cnt) := iv_item_code3;
    END IF;
--
    -- �����P
    IF (TRIM(iv_customer_code1) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code1;
    END IF;
    -- �����Q
    IF (TRIM(iv_customer_code2) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code2;
    END IF;
    -- �����R
    IF (TRIM(iv_customer_code3) IS NOT NULL) THEN
      ln_vender_cnt := l_rec_vender.vender_code.COUNT + 1;
      l_rec_vender.vender_code(ln_vender_cnt) := iv_customer_code3;
    END IF;
--
    -- ===============================
    -- C-2.�p�����[�^�`�F�b�N
    -- ===============================
    proc_check_param(
      iv_date_type       => iv_date_type,       -- ���t�^�C�v(1:������ 2:�[����)
      iv_start_date      => iv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- ���ԏI����(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- ���i�敪
      iv_item_type       => iv_item_type,       -- �i�ڋ敪
      ior_item           => l_rec_item,         -- �i�ڏ��
      ior_vender         => l_rec_vender,       -- �������
      ov_start_date      => lv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
      ov_end_date        => lv_end_date,        -- ���ԏI����(YYYY/MM/DD)
      ov_item_type_name  => lv_item_type_name,  -- �i�ڋ敪��
      ov_goods_type_name => lv_goods_type_name, -- ���i�敪��
      ov_errbuf          => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode         => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg          => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- C-3,C-4.�������׃f�[�^�擾
    -- ===============================
    proc_get_po_data(
      iv_date_type       => iv_date_type,       -- ���t�^�C�v(1:������ 2:�[����)
      iv_start_date      => lv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
      iv_end_date        => lv_end_date,        -- ���ԏI����(YYYY/MM/DD)
      iv_item_type_name  => lv_item_type_name,  -- �i�ڋ敪��
      iv_goods_type_name => lv_goods_type_name, -- ���i�敪��
      ir_item            => l_rec_item,         -- �i�ڏ��
      ir_vender          => l_rec_vender,       -- �������
      ot_data_rec        => lt_data_rec,        -- �������
      ov_errbuf          => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode         => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg          => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_user_expt;
    ELSE
      NULL;
    END IF;
--
    <<main_data_loop>>
    FOR i IN 1..lt_data_rec.COUNT LOOP
--
      -- �ϐ�������
      gn_depo_flg         := 0;
      gn_cane_flg         := 0;
      ln_price_header_id  := NULL;
      ln_total_amount     := 0;
      ln_cohi_unit_price  := 0;
      ln_depo_commission  := 0;
      ln_cane             := 0;
      ln_cohi_rest        := 0;
      lr_lot_data         := NULL;
--;
      -- ===============================
      -- ���b�g���擾
      -- ===============================
      proc_get_lot_data(
        iv_date_type        =>  iv_date_type,               -- ���t�^�C�v(1:������ 2:�[����)
        iv_start_date       =>  lv_start_date,              -- ���ԊJ�n��(YYYY/MM/DD)
        iv_end_date         =>  lv_end_date,                -- ���ԏI����(YYYY/MM/DD)
        ir_po_data          =>  lt_data_rec(i),             -- �������
        or_lot_data         =>  lr_lot_data,                -- ���b�g���
        ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
        ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
        ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--
      IF (((iv_date_type = gv_mgc_day) AND (lr_lot_data.lot_id IS NOT NULL))
        OR (iv_date_type = gv_deliver_day))THEN
--
        -- �Ώی���COUNT
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ===============================
        -- C-5.�d���P���f�[�^�擾
        -- ===============================
        proc_get_unit_price(
          iv_date_type        =>  iv_date_type,               -- ���t�^�C�v(1:������ 2:�[����)
          ir_po_data          =>  lt_data_rec(i),             -- �������
          ir_lot_data         =>  lr_lot_data,                -- ���b�g���
          on_price_header_id  =>  ln_price_header_id,         -- �w�b�_ID
          on_total_amount     =>  ln_total_amount,            -- ���󍇌v
          ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
          ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
          ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[����
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- �d���P���擾���̂ݏ����Ώ�
        IF (ln_price_header_id IS NOT NULL) THEN
          -- ===============================
          -- C-6.�v�Z����
          -- ===============================
          proc_calc_data(
            ir_po_data          =>  lt_data_rec(i),             -- �������
            in_total_amount     =>  ln_total_amount,            -- ���󍇌v
            on_cohi_unit_price  =>  ln_cohi_unit_price,         -- ������P��
            on_depo_commission  =>  ln_depo_commission,         -- �a����K���z
            on_cane             =>  ln_cane,                    -- ���ۋ��z
            on_cohi_rest        =>  ln_cohi_rest,               -- ��������z
            ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
            ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
            ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
          -- �G���[����
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- C-7.�������X�V����
          -- ===============================
          proc_upd_po_data(
            ir_po_data          =>  lt_data_rec(i),             -- �������
            in_total_amount     =>  ln_total_amount,            -- ���󍇌v
            in_cohi_unit_price  =>  ln_cohi_unit_price,         -- ������P��
            in_depo_commission  =>  ln_depo_commission,         -- �a����K���z
            in_cane             =>  ln_cane,                    -- ���ۋ��z
            in_cohi_rest        =>  ln_cohi_rest,               -- ��������z
            ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
            ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
            ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
          -- �G���[����
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
--
          -- ===============================
          -- C-8.���b�g�̍݌ɒP���X�V
          -- ===============================
          proc_upd_lot_data(
            ir_po_data          =>  lt_data_rec(i),             -- �������
            ir_lot_data         =>  lr_lot_data,                -- ���b�g���
            in_total_amount     =>  ln_total_amount,            -- ���󍇌v
            in_cohi_unit_price  =>  ln_cohi_unit_price,         -- ������P��
            in_depo_commission  =>  ln_depo_commission,         -- �a����K���z
            in_cane             =>  ln_cane,                    -- ���ۋ��z
            in_cohi_rest        =>  ln_cohi_rest,               -- ��������z
            ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
            ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
            ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
          -- �G���[����
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- C-9.�����ϔ������׏��o��
          -- ===============================
          proc_put_po_log(
            iv_msg_no         =>  gv_msg_xxpo30032,              -- ���b�Z�[�W�ԍ�
            iv_tkn_itm_no     =>  gv_tkn_item_no,                -- �g�[�N���i��
            iv_tkn_h_no       =>  gv_tkn_h_no,                   -- �g�[�N�������ԍ�
            iv_tkn_m_no       =>  gv_tkn_m_no,                   -- �g�[�N����������
            iv_tkn_nonyu_date =>  gv_tkn_nonyu_date,             -- �g�[�N���[����
            iv_po_no          =>  lt_data_rec(i).po_no,          -- �����ԍ�
            iv_po_l_no        =>  lt_data_rec(i).po_l_no,        -- ���הԍ�
            iv_item_no        =>  lt_data_rec(i).item_no,        -- �i�ڔԍ�
            iv_delivery_day   =>  lt_data_rec(i).delivery_day,   -- �[����
            ov_errbuf         =>  lv_errbuf,                     -- �G���[�E���b�Z�[�W
            ov_retcode        =>  lv_retcode,                    -- ���^�[���E�R�[�h
            ov_errmsg         =>  lv_errmsg);                    -- ���[�U�[�E�G���[�E���b�Z�[�W
--
          -- �G���[����
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- �d���P���w�b�_�[ID�̊i�[
          lt_p_header_id(ln_p_h_cnt) := ln_price_header_id;
--
          -- �d���P���w�b�_�[�X�V�����̎擾
          ln_p_h_cnt := ln_p_h_cnt + 1;
--
        END IF;
--
      END IF;
--
    END LOOP main_data_loop ;
--
    <<ph_loop>>
    FOR i IN 1..lt_p_header_id.COUNT LOOP
      -- ===============================
      -- C-10.�d��/�W���P���w�b�_(�A�h�I��)�̕ύX�����t���O���X�V
      -- ===============================
      proc_upd_price_headers_flg(
        in_price_header_id  =>  lt_p_header_id(i),          -- �w�b�_ID
        ov_errbuf           =>  lv_errbuf,                  -- �G���[�E���b�Z�[�W
        ov_retcode          =>  lv_retcode,                 -- ���^�[���E�R�[�h
        ov_errmsg           =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
      -- �G���[����
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP ph_loop ;
--
    -- ===============================
    -- C-11.�������ʏo��
    -- ===============================
    proc_put_process_result(
      ov_errbuf          => lv_errbuf,                    -- �G���[�E���b�Z�[�W
      ov_retcode         => lv_retcode,                   -- ���^�[���E�R�[�h
      ov_errmsg          => lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �d���P�����P�ł��擾�ł��Ȃ������ꍇ�͌x���I��
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
    WHEN global_user_expt THEN   --*** ���[�U�[��`��O ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf             OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_date_type       IN  VARCHAR2,      --   ���t�^�C�v(1:������ 2:�[����)
    iv_start_date      IN  VARCHAR2,      --   ���ԊJ�n��(YYYY/MM/DD)
    iv_end_date        IN  VARCHAR2,      --   ���ԏI����(YYYY/MM/DD)
    iv_commodity_type  IN  VARCHAR2,      --   ���i�敪
    iv_item_type       IN  VARCHAR2,      --   �i�ڋ敪
    iv_item_code1      IN  VARCHAR2,      --   �i�ڃR�[�h1
    iv_item_code2      IN  VARCHAR2,      --   �i�ڃR�[�h2
    iv_item_code3      IN  VARCHAR2,      --   �i�ڃR�[�h3
    iv_customer_code1  IN  VARCHAR2,      --   �����R�[�h1
    iv_customer_code2  IN  VARCHAR2,      --   �����R�[�h2
    iv_customer_code3  IN  VARCHAR2       --   �����R�[�h3
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
    gv_exec_user := FND_GLOBAL.USER_NAME;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
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
      iv_date_type       => iv_date_type,       -- ���t�^�C�v(1:������ 2:�[����)
      iv_start_date      => iv_start_date,      -- ���ԊJ�n��(YYYY/MM/DD)
      iv_end_date        => iv_end_date,        -- ���ԏI����(YYYY/MM/DD)
      iv_commodity_type  => iv_commodity_type,  -- ���i�敪
      iv_item_type       => iv_item_type,       -- �i�ڋ敪
      iv_item_code1      => iv_item_code1,      -- �i�ڃR�[�h1
      iv_item_code2      => iv_item_code2,      -- �i�ڃR�[�h2
      iv_item_code3      => iv_item_code3,      -- �i�ڃR�[�h3
      iv_customer_code1  => iv_customer_code1,  -- �����R�[�h1
      iv_customer_code2  => iv_customer_code2,  -- �����R�[�h2
      iv_customer_code3  => iv_customer_code3,  -- �����R�[�h3
      ov_errbuf          => lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode         => lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg          => lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) OR (lv_retcode = gv_status_warn) THEN
      IF (lv_errmsg IS NULL) THEN
        IF (lv_retcode <> gv_status_warn) THEN
          --��^���b�Z�[�W�E�Z�b�g
          lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
        END IF;
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- D-15.���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
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
    AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
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
END xxpo870003c;
/
