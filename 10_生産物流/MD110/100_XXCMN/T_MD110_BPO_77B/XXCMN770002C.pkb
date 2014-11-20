CREATE OR REPLACE PACKAGE BODY xxcmn770002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770002C(body)
 * Description      : �󕥎c���\�i�T�j���i
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77B)
 * Version          : 1.6
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize              PROCEDURE : �O����
 *  prc_get_report_data         PROCEDURE : ���׃f�[�^�擾(B-1)
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/08    1.0   T.Hokama         �V�K�쐬
 *  2008/05/15    1.1   T.Endou          �s�ID11,13�Ή�
 *                                       11 ���̓p���A������yyyym�Ή�
 *                                       13 �w�b�_�[�����̍ő啶���������̕ύX
 *  2008/05/30    1.2   R.Tomoyose       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/12    1.3   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜�B
 *                                       ����敪�� = �d����ԕi�͕��o�����o�͈ʒu�͎���̕�����
 *                                       �o�͂���B
 *  2008/06/24    1.4   T.Endou          ���ʁE���z���ڂ�NULL�ł�0�o�͂���B
 *                                       ���ʁE���z�̊Ԃ��l�߂�B
 *  2008/06/25    1.5   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/05    1.6   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma02_v�v
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770002C' ;           -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '�󕥎c���\�i�T�j���i' ;   -- ���[��
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_language_code           CONSTANT VARCHAR2(2)  := 'JA' ;
  gc_enable_flag             CONSTANT VARCHAR2(2)  := 'Y' ;
  gc_lookup_type_print_class CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE' ; -- ���[���
  gc_lookup_type_print_flg   CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';  -- �����
  gc_lookup_type_crowd_kind  CONSTANT VARCHAR2(50) := 'XXCMN_MC_OUPUT_DIV' ;            -- �Q���
  gc_lookup_type_dealing_div CONSTANT VARCHAR2(50) := 'XXCMN_DEALINGS_DIV' ;            -- ����敪
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- ���[���
  ------------------------------
  gc_print_kind_locat     CONSTANT VARCHAR2(1) := '1';    --�q�ɕʁE�i�ڕ�
  gc_print_kind_item      CONSTANT VARCHAR2(1) := '2';    --�i�ڕ�
--
   ------------------------------
  -- �Q���
  ------------------------------
  gc_crowd_kind           CONSTANT VARCHAR2(1) := '3';    --�Q��
  gc_crowd_acct_kind      CONSTANT VARCHAR2(1) := '4';    --�o���Q��
--
  ------------------------------
  -- �����Ǘ��敪
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0' ;   --���ی���
  gc_cost_st              CONSTANT VARCHAR2(1) := '1' ;   --�W������
  ------------------------------
  -- ���b�g�Ǘ�
  ------------------------------
  gn_lot_ctl_n            CONSTANT NUMBER := 0;  --�ΏۊO
  gn_lot_ctl_y            CONSTANT NUMBER := 1;  --�Ώ�
--
  ------------------------------
  -- �󕥋敪
  ------------------------------
  gc_rcv_pay_div_in       CONSTANT VARCHAR2(1) := '1' ;   --���
  gc_rcv_pay_div_out      CONSTANT VARCHAR2(2) := '-1' ;  --���o
--
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_t_format        CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24MISS' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  gn_one                 CONSTANT NUMBER      := 1   ;
  gn_two                 CONSTANT NUMBER      := 2   ;
--
  ------------------------------
  -- ���ڈʒu���f
  ------------------------------
  -- ���ڔ���p
  gc_break_col             VARCHAR2(100) DEFAULT '-' ;     -- ���ڔ���؂�ւ�
  -- ���
  gc_col_no_po             CONSTANT VARCHAR2(2) := '1';    -- �d��
  gc_col_no_wrap           CONSTANT VARCHAR2(2) := '2';    -- �
  gc_col_no_set            CONSTANT VARCHAR2(2) := '3';    -- �Z�b�g
  gc_col_no_oki            CONSTANT VARCHAR2(2) := '4';    -- ����
  gc_col_no_trnsfr         CONSTANT VARCHAR2(2) := '5';    -- �U�֓���
  gc_col_no_acct_1         CONSTANT VARCHAR2(2) := '6';    -- �Ήc�P
  gc_col_no_acct_2         CONSTANT VARCHAR2(2) := '7';    -- �Ήc�Q
  gc_col_no_guift          CONSTANT VARCHAR2(2) := '8';    -- �h�����N�M�t�g
  gc_col_no_locat_chg      CONSTANT VARCHAR2(2) := '9';    -- �q��
  gc_col_no_ret_goods      CONSTANT VARCHAR2(2) := '10';   -- �ԕi
  gc_col_no_other          CONSTANT VARCHAR2(2) := '11';   -- ���̑�
  -- ���o
  gc_col_no_out_set        CONSTANT VARCHAR2(2) := '12';   -- �Z�b�g
  gc_col_no_out_mtrl       CONSTANT VARCHAR2(2) := '13';   -- �ԕi������
  gc_col_no_out_dismnt     CONSTANT VARCHAR2(2) := '14';   -- ��̔����i��
  gc_col_no_out_pay        CONSTANT VARCHAR2(2) := '15';   -- �L��
  gc_col_no_out_trnsfr     CONSTANT VARCHAR2(2) := '16';   -- �U�֗L��
  gc_col_no_out_point      CONSTANT VARCHAR2(2) := '17';   -- ���_
  gc_col_no_out_guift      CONSTANT VARCHAR2(2) := '18';   -- �h�����N�M�t�g
  gc_col_no_out_other      CONSTANT VARCHAR2(2) := '19';   -- ���̑�
--
  ------------------------------
  -- ���l�E���z�����_�ʒu
  ------------------------------
  gn_quantity_decml        NUMBER  := 3;
  gn_amount_decml          NUMBER  := 0;
--
  ------------------------------
  -- �����^�C�v
  ------------------------------
  gv_doc_type_xfer           CONSTANT VARCHAR2(5)     := 'XFER';  --
  gv_doc_type_trni           CONSTANT VARCHAR2(5)     := 'TRNI';  --
  gv_doc_type_adji           CONSTANT VARCHAR2(5)     := 'ADJI';  --
  gv_doc_type_prod           CONSTANT VARCHAR2(5)     := 'PROD';  --
  gv_doc_type_porc           CONSTANT VARCHAR2(5)     := 'PORC';  --
  gv_doc_type_omso           CONSTANT VARCHAR2(5)     := 'OMSO';  --
--
  ------------------------------
  -- ���R�R�[�h
  ------------------------------
  gv_reason_code_xfer        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_trni        CONSTANT VARCHAR2(5)   := 'X122';--
  gv_reason_code_adji_po     CONSTANT VARCHAR2(5)   := 'X201';--�d��
  gv_reason_code_adji_hama   CONSTANT VARCHAR2(5)   := 'X988';--�l��
  gv_reason_code_adji_move   CONSTANT VARCHAR2(5)   := 'X123';--�ړ�
  gv_reason_code_adji_othr   CONSTANT VARCHAR2(5)   := 'X977';--�����i�o�͑ΏۊO�j
  gv_reason_code_adji_itm    CONSTANT VARCHAR2(5)   := 'X942';-- �َ��i�ڕ��o
  gv_reason_code_adji_snt    CONSTANT VARCHAR2(5)   := 'X951';-- ���̑����o
--
  ------------------------------
  -- ����敪
  ------------------------------
  gv_dealings_div_prod1      CONSTANT VARCHAR2(10)  := '�i��U��';
  gv_dealings_div_prod2      CONSTANT VARCHAR2(10)  := '�i�ڐU��';
  gv_dealings_name_po        CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�d��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(6)                          -- �����N��
     ,goods_class         mtl_categories_b.segment1%TYPE       -- ���i�敪
     ,item_class          mtl_categories_b.segment1%TYPE       -- �i�ڋ敪
     ,print_kind          VARCHAR2(1)                          -- ���[���
     ,locat_code          ic_tran_pnd.location%TYPE            -- �q�ɃR�[�h
     ,crowd_kind          fnd_lookup_values.meaning%TYPE       -- �Q���
     ,crowd_code          mtl_categories_b.segment1%TYPE       -- �Q�R�[�h
     ,acct_crowd_code     mtl_categories_b.segment1%TYPE       -- �o���Q�R�[�h
    ) ;
--
  -- �󕥎c���\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD(
      locat_code            ic_whse_mst.whse_code%TYPE              -- �q�ɃR�[�h
     ,locat_name            ic_whse_mst.whse_name%TYPE              -- �q�ɖ�
     ,item_id               xxcmn_item_mst2_v.item_id%TYPE          -- �i��ID
     ,lot_id                ic_tran_pnd.lot_id%TYPE                 -- ���b�gID
     ,trans_qty             ic_tran_pnd.trans_qty%TYPE              -- �������
     ,cost_kbn              ic_item_mst_b.attribute15%TYPE          -- �����Ǘ��敪
     ,lot_ctl               xxcmn_lot_each_item_v.lot_ctl%TYPE      -- ���b�g�Ǘ�
     ,actual_unit_price     xxcmn_lot_cost.unit_ploce%TYPE          -- ���ی���
     ,column_no             fnd_lookup_values.attribute2%TYPE       -- ���ڈʒu
     ,rcv_pay_div           xxcmn_rcv_pay_mst.rcv_pay_div%TYPE      -- �󕥋敪
     ,trans_date            DATE                                    -- �����
     ,crowd_code            mtl_categories_b.segment1%TYPE          -- �Q�R�[�h
     ,crowd_low             mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i���j
     ,crowd_mid             mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i���j
     ,crowd_high            mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i��j
     ,item_code             xxcmn_item_mst2_v.item_no%TYPE          -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst2_v.item_name%TYPE        -- �i�ږ���
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
--
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- �S����
  gv_print_class_name       fnd_lookup_values.meaning%TYPE;                   -- ���[��ʖ�
  gv_goods_class_name       mtl_categories_tl.description%TYPE;               -- ���i�敪��
  gv_item_class_name        mtl_categories_tl.description%TYPE;               -- �i�ڋ敪��
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;               -- �Q��ʖ�
--
  ------------------------------
  -- �����擾�p
  ------------------------------
  gv_exec_year_month_bef    VARCHAR2(6);      -- �����N���̑O��
  gd_exec_start             DATE;             -- �����N���̊J�n��
  gd_exec_end               DATE;             -- �����N���̏I����
  gv_exec_start             VARCHAR2(20);     -- �����N���̊J�n��
  gv_exec_end               VARCHAR2(20);     -- �����N���̏I����
  gv_exec_start_bef         VARCHAR2(20);     -- �����N���̑O���J�n��
  gv_exec_end_bef           VARCHAR2(20);     -- �����N���̑O���I����
  gv_exec_start_aft         VARCHAR2(20);     -- �����N���̗����J�n��
  gv_exec_end_aft           VARCHAR2(20);     -- �����N���̗����I����
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12) ;    -- ���[ID
  gd_exec_date              DATE         ;    -- ���{��
--
  gt_main_data              tab_data_type_dtl ;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER DEFAULT 0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml(
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>' ;
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����
   ***********************************************************************************/
  PROCEDURE prc_initialize(
      ir_param      IN     rec_param_data   -- 01.���̓p�����[�^�Q
     ,ov_errbuf     OUT    VARCHAR2         --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT    VARCHAR2         --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT    VARCHAR2         --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
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
    lc_f_day           CONSTANT VARCHAR2(2)  := '01';
    lc_ym              CONSTANT VARCHAR2(6)  := 'YYYYMM';
    lc_f_time          CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time          CONSTANT VARCHAR2(10) := ' 23:59:59';
    -- �G���[�R�[�h
    lc_err_code        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010';
    -- �g�[�N����
    lc_token_name_01   CONSTANT VARCHAR2(100) := 'PARAMETER';
    lc_token_name_02   CONSTANT VARCHAR2(100) := 'VALUE';
    -- �g�[�N���l
    lc_token_value     CONSTANT VARCHAR2(100) := '�����N��';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id );
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id );
--
    -- ====================================================
    -- ���[��ʎ擾
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_print_class_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.print_kind
      AND    flv.lookup_type   = gc_lookup_type_print_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- ���i�敪�擾
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_goods_class_name
      FROM   xxcmn_categories2_v cat
      WHERE  cat.category_set_name = gc_cat_set_goods_class
      AND    cat.segment1          = ir_param.goods_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- �i�ڋ敪�擾
    -- ====================================================
    BEGIN
      SELECT cat.description
      INTO   gv_item_class_name
      FROM   xxcmn_categories2_v cat
      WHERE  cat.category_set_name = gc_cat_set_item_class
      AND    cat.segment1          = ir_param.item_class
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- �Q��ʎ擾
    -- ====================================================
    BEGIN
      SELECT flv.meaning
      INTO   gv_crowd_kind_name
      FROM   xxcmn_lookup_values_v flv
      WHERE  flv.lookup_code   = ir_param.crowd_kind
      AND    flv.lookup_type   = gc_lookup_type_crowd_kind
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- �����N��
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    gd_exec_start := FND_DATE.STRING_TO_DATE( ir_param.exec_year_month, gc_char_m_format ) ;
    IF ( gd_exec_start IS NULL ) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_retcode := gv_status_error ;
      lv_errbuf  := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                             ,iv_name          => lc_err_code
                                             ,iv_token_name1   => lc_token_name_01
                                             ,iv_token_name2   => lc_token_name_02
                                             ,iv_token_value1  => lc_token_value
                                             ,iv_token_value2  => ir_param.exec_year_month ) ;
      RAISE get_value_expt ;
    END IF ;
--
    -- ====================================================
    -- ���t���擾
    -- ====================================================
    -- �����N���E�J�n��
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month , gc_char_m_format);
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
    -- �����N���E�I����
    gd_exec_end   := LAST_DAY(gd_exec_start);
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_e_time;
    -- �O���E�N��
    gv_exec_year_month_bef := TO_CHAR(ADD_MONTHS(gd_exec_start , -1), lc_ym);
    -- �����N���E�O���J�n��
    gv_exec_start_bef := TO_CHAR(ADD_MONTHS(gd_exec_start , -1), gc_char_dt_format);
    -- �����N���E�O���I����
    gv_exec_end_bef   := TO_CHAR(gd_exec_start -1, gc_char_d_format) || lc_e_time;
    -- �����N���E�����J�n��
    gv_exec_start_aft := TO_CHAR(ADD_MONTHS(gd_exec_start , 1), gc_char_dt_format);
    -- �����N���E�����I����
    gv_exec_end_aft  := TO_CHAR(LAST_DAY(ADD_MONTHS(gd_exec_start, 1))
                                ,gc_char_d_format) || lc_e_time;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errbuf ;
      ov_retcode := lv_retcode ;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(B-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
      ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
     ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
     ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
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
    -- *** ���[�J���E�萔 ***
--
    -- *** ���[�J���E�ϐ� ***
    lv_select1    VARCHAR2(5000) ;
    lv_select2    VARCHAR2(5000) ;
    lv_from       VARCHAR2(5000) ;
    lv_where      VARCHAR2(5000) ;
    lv_order_by   VARCHAR2(5000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql2       VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
    lv_sql_xfer      VARCHAR2(5000);
    lv_sql_trni      VARCHAR2(5000);
    lv_sql_adji      VARCHAR2(5000);
    lv_sql_adji_po   VARCHAR2(5000);
    lv_sql_adji_hm   VARCHAR2(5000);
    lv_sql_adji_mv   VARCHAR2(5000);
    lv_sql_adji_snt  VARCHAR2(5000);
    lv_sql_prod      VARCHAR2(5000);
    lv_sql_prod_rv   VARCHAR2(5000);
    lv_sql_porc      VARCHAR2(5000);
    lv_sql_porc_po   VARCHAR2(5000);
    lv_sql_omsso     VARCHAR2(5000);
    --xfer
    lv_from_xfer         VARCHAR2(5000);
    lv_where_xfer        VARCHAR2(5000);
    --trni
    lv_from_trni         VARCHAR2(5000);
    lv_where_trni        VARCHAR2(5000);
    --adji�i�d���j
    lv_from_adji_po      VARCHAR2(5000);
    lv_where_adji_po     VARCHAR2(5000);
    --adji�i�l���j
    lv_from_adji_hm      VARCHAR2(5000);
    lv_where_adji_hm     VARCHAR2(5000);
    --adji�i�ړ��j
    lv_from_adji_mv      VARCHAR2(5000);
    lv_where_adji_mv     VARCHAR2(5000);
    --adji�i���̑����o�j
    lv_from_adji_snt     VARCHAR2(5000);
    lv_where_adji_snt    VARCHAR2(5000);
    --adji�i��L�ȊO�j
    lv_from_adji         VARCHAR2(5000);
    lv_where_adji        VARCHAR2(5000);
    --prod�iReverse_id�Ȃ��j�i��E�i�ڐU�ֈȊO
    lv_from_prod         VARCHAR2(5000);
    lv_where_prod        VARCHAR2(5000);
    --porc
    lv_select_porc       VARCHAR2(5000);
    lv_from_porc         VARCHAR2(5000);
    lv_where_porc        VARCHAR2(5000);
    --porc�i�d���j
    lv_from_porc_po      VARCHAR2(5000);
    lv_where_porc_po     VARCHAR2(5000);
    --omsso
    lv_select_omsso      VARCHAR2(5000);
    lv_from_omsso        VARCHAR2(5000);
    lv_where_omsso       VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
--
    lv_select1 := '  SELECT';
    --�q�ɕʂ�I�������ꍇ�͑q�ɃR�[�h���擾����B
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_select1 := lv_select1
              || ' iwm.whse_code            h_whse_code'            -- �w�b�_�F�q�ɃR�[�h
              || ',iwm.whse_name            h_whse_name'            -- �w�b�_�F�q�ɖ���
             ;
    ELSE
      lv_select1 := lv_select1
              || ' NULL                     h_whse_code'            -- �w�b�_�F�q�ɃR�[�h
              || ',NULL                     h_whse_name'            -- �w�b�_�F�q�ɖ���
             ;
    END IF;
    lv_select1 := lv_select1
              || ',trn.item_id              item_id'           -- �i��ID
              || ',trn.lot_id               lot_id'            -- ���b�gID
              || ',trn.trans_qty            trans_qty'         -- �������
              || ',xleiv.item_attribute15   cost_mng_clss'     -- �����Ǘ��敪
              || ',xleiv.lot_ctl            lot_ctl'           -- ���b�g�Ǘ�
              || ',xleiv.actual_unit_price  actual_unit_price' -- ���ےP��
              || ',CASE WHEN INSTR(xlvv.attribute2,''' || gc_break_col || ''') = 0'
              || '           THEN '''''
              || '      WHEN xrpmxv.rcv_pay_div = ' || gc_rcv_pay_div_in
              || '           THEN SUBSTR(xlvv.attribute2,1,'
              || '                INSTR(xlvv.attribute2,''' || gc_break_col || ''') -1)'
              || '      WHEN xrpmxv.dealings_div_name = ''' || gv_dealings_name_po || ''''
              || '           THEN SUBSTR(xlvv.attribute2,1,'
              || '                INSTR(xlvv.attribute2,''' || gc_break_col || ''') -1)'
              || '      ELSE'
              || '                SUBSTR(xlvv.attribute2,INSTR(xlvv.attribute2,'''
              ||                                         gc_break_col || ''') +1)'
              || ' END  column_no'                             -- ���ڈʒu
              || ',xrpmxv.rcv_pay_div       rcv_pay_div'       -- �󕥋敪
              || ',trn.trans_date           trans_date'        -- �����
              ;
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
      lv_select1 := lv_select1 || ',xleiv.crowd_code                crowd_code'      --�Q�R�[�h
                               || ',SUBSTR(xleiv.crowd_code, 1, 3)  crowd_low'       --���Q
                               || ',SUBSTR(xleiv.crowd_code, 1, 2)  crowd_mid'       --���Q
                               || ',SUBSTR(xleiv.crowd_code, 1, 1)  crowd_high'      --��Q
                                ;
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
      lv_select1 := lv_select1 || ',xleiv.acnt_crowd_code  crowd_code'               --�o���Q�R�[�h
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 3)  crowd_low'  --���Q
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 2)  crowd_mid'  --���Q
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 1)  crowd_high' --��Q
                               ;
    END IF;
    lv_select2 := ''
              || ',xleiv.item_code          item_code'         -- �i�ڃR�[�h
              || ',xleiv.item_short_name    item_name'         -- �i�ږ���
               ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
--
    lv_from :=  ' FROM '
            || ' xxcmn_lot_each_item_v     xleiv'    -- ���b�g�ʕi�ڏ��
            || ',xxcmn_lookup_values2_v    xlvv'     -- �N�C�b�N�R�[�h���view2
            ;
    --�q�ɕʂ�I�������ꍇ�͑q�Ƀ}�X�^����������B
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_from :=  lv_from
              || ',ic_whse_mst             iwm'      -- OPM�q�Ƀ}�X�^
              ;
    END IF;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || ' trn.trans_date >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''',  '''
             ||                                             gc_char_dt_format || ''')'--�����
             || ' AND trn.trans_date <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''',  '''
             ||                                                 gc_char_dt_format || ''')'--�����
             || ' AND ((xleiv.start_date_active IS NULL)'
             || '      OR (xleiv.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND ((xleiv.end_date_active IS NULL)'
             || '      OR (xleiv.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND xleiv.item_id    = trn.item_id'
             || ' AND xleiv.lot_id     = trn.lot_id'
             || ' AND xlvv.attribute2 IS NOT NULL'
             ;
    ---------------------------------------------------------------------------------------------
    --  ���b�N�A�b�v�i�Ώے��[�j
    lv_where :=  lv_where
      || ' AND xlvv.lookup_type       = ''' || gc_lookup_type_print_flg || ''''
      || ' AND xrpmxv.dealings_div    = xlvv.meaning'
      || ' AND xlvv.enabled_flag      = ''Y'''
      || ' AND (xlvv.start_date_active IS NULL OR'
      || ' xlvv.start_date_active  <= TRUNC(trn.trans_date))'
      || ' AND (xlvv.end_date_active   IS NULL OR'
      || ' xlvv.end_date_active    >= TRUNC(trn.trans_date))'
      ;
    ---------------------------------------------------------------------------------------------
    -- ���[��ʁ��P�F�q�ɕʁE�i�ڕʂ̏ꍇ
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_where := lv_where
               || ' AND iwm.whse_code  = trn.whse_code'
               ;
      -- �q�ɃR�[�h���w�肳��Ă���ꍇ
      IF (ir_param.locat_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND iwm.whse_code = ''' || ir_param.locat_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- �Q�R�[�h�����͂���Ă���ꍇ
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.crowd_code  = ''' || ir_param.crowd_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
    IF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- �o���Q�R�[�h�����͂���Ă���ꍇ
       IF (ir_param.acct_crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.acnt_crowd_code  = ''' || ir_param.acct_crowd_code || ''''
                 ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- SQL����( XFER :�o���󕥋敪���u�h�v�ړ��ϑ�����j
    -- ----------------------------------------------------
    lv_from_xfer := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_xfer_v  xrpmxv'   --  ��VIW
      || ',ic_xfer_mst               ixm'      -- �n�o�l�݌ɓ]���}�X�^
      || ',xxinv_mov_req_instr_lines xmril'    -- �ړ��˗��^�w�����ׁi�A�h�I���j
       ;
--
    lv_where_xfer :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_xfer    || '''' --�����^�C�v
      || ' AND trn.reason_code         = ''' || gv_reason_code_xfer || '''' --���R�R�[�h
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND trn.doc_id              = ixm.transfer_id'
      || ' AND ixm.attribute1          = xmril.mov_line_id'
       ;
    -- �r�p�k����(XFER)
    lv_sql_xfer := lv_select1 || lv_select2 || lv_from || lv_from_xfer
                || lv_where || lv_where_xfer;
--
    -- ----------------------------------------------------
    -- SQL����( TRNI :�o���󕥋敪���u�h�v�ړ��ϑ��Ȃ��j
    -- ----------------------------------------------------
    lv_from_trni := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_trni_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- �n�o�l�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- �n�o�l�W���[�i���}�X�^
      || ',xxinv_mov_req_instr_lines xmril'    -- �ړ��˗��^�w�����ׁi�A�h�I���j
       ;
--
    lv_where_trni :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_trni    || '''' --�����^�C�v
      || ' AND trn.reason_code         = ''' || gv_reason_code_trni || '''' --���R�R�[�h
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_type           = xrpmxv.rcv_pay_div'                --���C���^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND trn.doc_type            = iaj.trans_type'
      || ' AND trn.doc_id              = iaj.doc_id'
      || ' AND trn.doc_line            = iaj.doc_line'
      || ' AND iaj.journal_id          = ijm.journal_id'
      || ' AND ijm.attribute1          = xmril.mov_line_id'
       ;
    -- �r�p�k����(TRNI)
    lv_sql_trni := lv_select1 || lv_select2 || lv_from || lv_from_trni
                || lv_where || lv_where_trni;
--
    -- ----------------------------------------------------
    -- SQL����( ADJI :�o���󕥋敪���u�h�v�݌ɒ���(��)
    -- ----------------------------------------------------
    lv_from_adji := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
       ;
--
    lv_where_adji :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_po || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_hama || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_move || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_othr || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_itm || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_snt || ''''
       ;
    -- �r�p�k����(adji)��
    lv_sql_adji := lv_select1 || lv_select2 || lv_from || lv_from_adji
                || lv_where || lv_where_adji;
--
    -- ----------------------------------------------------
    -- SQL����( ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�d��)
    -- ----------------------------------------------------
--
    lv_from_adji_po := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_rcv_and_rtn_txns     xrrt'     -- ����ԕi���уA�h�I��
       ;
--
    lv_where_adji_po :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_po || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xrrt.txns_id            = ijm.attribute1'
       ;
    -- �r�p�k����(adji)�d��
    lv_sql_adji_po := lv_select1 || lv_select2 || lv_from || lv_from_adji_po
                   || lv_where || lv_where_adji_po;
--
    -- ----------------------------------------------------
    -- SQL����( ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�l��)
    -- ----------------------------------------------------
    lv_from_adji_hm := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_namaha_prod_txns     xnpt'     -- ���Z���уA�h�I��
       ;
--
    lv_where_adji_hm :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_hama || ''''
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xnpt.entry_number       = ijm.attribute1'
       ;
    -- �r�p�k����(adji)�d��
    lv_sql_adji_hm := lv_select1 || lv_select2 || lv_from || lv_from_adji_hm
                   || lv_where || lv_where_adji_hm;
--
    -- ----------------------------------------------------
    -- SQL����( ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�ړ�)
    -- ----------------------------------------------------
    lv_from_adji_mv := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_vendor_supply_txns   xvst'     -- �O���o��������
       ;
--
    lv_where_adji_mv :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_move || ''''
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
      || ' AND iaj.trans_type          = trn.doc_type'
      || ' AND iaj.doc_id              = trn.doc_id'
      || ' AND iaj.doc_line            = trn.doc_line'
      || ' AND ijm.journal_id          = iaj.journal_id'
      || ' AND xvst.txns_id            = ijm.attribute1'
       ;
    -- �r�p�k����(adji)
    lv_sql_adji_mv := lv_select1 || lv_select2 || lv_from || lv_from_adji_mv
                   || lv_where || lv_where_adji_mv;
--
    -- ----------------------------------------------------
    -- SQL����( ADJI :�o���󕥋敪���u�h�v�݌ɒ���(���̑����o)
    -- ----------------------------------------------------
    lv_from_adji_snt := ''
      || ',ic_tran_cmp               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
       ;
--
    lv_where_adji_snt :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND ((trn.reason_code       = ''' || gv_reason_code_adji_itm || ''')'
      || '  OR  (trn.reason_code       = ''' || gv_reason_code_adji_snt || '''))'
      || ' AND xrpmxv.rcv_pay_div      = CASE'
      || '                                 WHEN trn.trans_qty >= 0 THEN 1'
      || '                               ELSE -1'
      || '                             END'
       ;
    -- �r�p�k����(adji)
    lv_sql_adji_snt := lv_select1 || lv_select2 || lv_from || lv_from_adji_snt
                    || lv_where || lv_where_adji_snt;
--
    -- ----------------------------------------------------
    -- SQL����( PROD :�o���󕥋敪���u�h�v���Y�֘A�iReverse_id�Ȃ��j�i��E�i�ڐU�ւȂ�
    -- ----------------------------------------------------
    lv_from_prod := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_prod_v  xrpmxv'   --  ��VIW
      || ',xxcmn_lookup_values2_v    xlvv2'    -- �N�C�b�N�R�[�h���view2
       ;
--
    lv_where_prod :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_prod    || '''' --�����^�C�v
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.reverse_id          IS NULL'
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_type           = xrpmxv.line_type'                  --���C���^�C�v
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --�o�b�`ID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_type           = xrpmxv.gmd_line_type'              --
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod1 || ''''   -- �i��U��
      || ' AND xlvv2.meaning          <> ''' || gv_dealings_div_prod2 || ''''   -- �i�ڐU��
      || ' AND xlvv2.lookup_type       = ''' || gc_lookup_type_dealing_div || ''''
      || ' AND xrpmxv.dealings_div     = xlvv2.lookup_code'
      || ' AND xlvv2.enabled_flag      = ''Y'''
      || ' AND (xlvv2.start_date_active IS NULL OR'
      || ' xlvv2.start_date_active    <= TRUNC(trn.trans_date))'
      || ' AND (xlvv2.end_date_active   IS NULL OR'
      || ' xlvv2.end_date_active      >= TRUNC(trn.trans_date))'
       ;
    -- �r�p�k����(prod)Reverse_id�Ȃ�
    lv_sql_prod := lv_select1 || lv_select2 || lv_from || lv_from_prod
                || lv_where || lv_where_prod;
--
    -- ----------------------------------------------------
    -- SQL����( PORC :�o���󕥋敪���u�h�v�w���֘A
    -- ----------------------------------------------------
    lv_select_porc := ''
                   || ',xitem.item_no            item_code'         -- �i�ڃR�[�h
                   || ',xitem.item_short_name    item_name'         -- �i�ږ���
                    ;
--
    lv_from_porc := ''
      || ',ic_tran_pnd                     trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_porc_rma02_v  xrpmxv'   --  ��VIW�iRMA�j
      || ',xxcmn_item_mst2_v               xitem'    -- �i�ڃ}�X�^VIEW
       ;
--
    lv_where_porc :=  ''
      || ' AND xrpmxv.prod_div         = ''' || ir_param.goods_class || ''''
      || ' AND xrpmxv.item_div         = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --�����^�C�v
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --�o�b�`ID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND xitem.item_id           = NVL(xrpmxv.item_id, trn.item_id)'
      || ' AND ((xitem.start_date_active IS NULL)'
      || '      OR (xitem.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
      || '          TRUNC(trn.trans_date)))'
      || ' AND ((xitem.end_date_active IS NULL)'
      || '      OR (xitem.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
      || '          TRUNC(trn.trans_date)))'
       ;
    -- �r�p�k����(porc)
    lv_sql_porc := lv_select1 || lv_select_porc || lv_from || lv_from_porc
                || lv_where || lv_where_porc;
--
    -- ----------------------------------------------------
    -- SQL����( PORC :�o���󕥋敪���u�h�v�w���֘A�i�d���j
    -- ----------------------------------------------------
    lv_from_porc_po := ''
      || ',ic_tran_pnd                  trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_porc_po_v  xrpmxv'   --  ��VIW�iPO�j
       ;
--
    lv_where_porc_po :=  ''
      || ' AND xleiv.prod_div          = ''' || ir_param.goods_class || ''''
      || ' AND xleiv.item_div          = ''' || ir_param.item_class || ''''
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --�����^�C�v
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --�o�b�`ID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.line_id             = xrpmxv.line_id'
       ;
    -- �r�p�k����(porc)�d��
    lv_sql_porc_po := lv_select1 || lv_select2 || lv_from || lv_from_porc_po
                   || lv_where || lv_where_porc_po;
--
    -- ----------------------------------------------------
    -- SQL����( OMSO :�o���󕥋敪���u�h�v�󒍊֘A
    -- ----------------------------------------------------
    lv_select_omsso := ''
                    || ',xitem.item_no            item_code'         -- �i�ڃR�[�h
                    || ',xitem.item_short_name    item_name'         -- �i�ږ���
                     ;
--
    lv_from_omsso := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_omso_v  xrpmxv'   --  ��VIW
      || ',xxcmn_item_mst2_v         xitem'    -- �i�ڃ}�X�^VIEW
       ;
--
    lv_where_omsso :=  ''
      || ' AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''','''
      ||                                                      gc_char_dt_format || ''')' -- ���ד�
      || ' AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''
      ||                                                      gc_char_dt_format || ''')' -- ���ד�
      || ' AND trn.doc_type         = ''' || gv_doc_type_omso    || '''' --�����^�C�v
      || ' AND trn.completed_ind    = 1'                                 --�����敪
      || ' AND trn.doc_type         = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_detail_id   = xrpmxv.doc_line'                   --
      || ' AND xrpmxv.prod_div      = ''' || ir_param.goods_class || ''''
      || ' AND xrpmxv.item_div      = ''' || ir_param.item_class || ''''
      || ' AND xitem.item_id        = NVL(xrpmxv.item_id, trn.item_id)'
      || ' AND ((xitem.start_date_active IS NULL)'
      || '      OR (xitem.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
      || '          TRUNC(trn.trans_date)))'
      || ' AND ((xitem.end_date_active IS NULL)'
      || '      OR (xitem.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
      || '          TRUNC(trn.trans_date)))'
       ;
    -- �r�p�k����(OMSO)
    lv_sql_omsso := lv_select1 || lv_select_omsso || lv_from || lv_from_omsso
                 || lv_where || lv_where_omsso;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    -- ���[��ʁ��P�F�q�ɕʁE�i�ڕʂ̏ꍇ
    IF (ir_param.print_kind = gc_print_kind_locat) THEN
      lv_order_by := ' ORDER BY'
                  || ' h_whse_code'     -- �w�b�_�F�q�ɃR�[�h
                  || ',crowd_code'      -- �Q�R�[�h
                  || ',item_code'       -- �i�ڃR�[�h
                  || ',column_no'       -- ���ڈʒu
                  || ',rcv_pay_div'     -- �󕥋敪
                  ;
    ELSE
      lv_order_by := ' ORDER BY'
                  || ' crowd_code'      -- �Q�R�[�h
                  || ',item_code'       -- �i�ڃR�[�h
                  || ',column_no'       -- ���ڈʒu
                  || ',rcv_pay_div'     -- �󕥋敪
                  ;
    END IF;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := ''
      ||  lv_sql_xfer
      ||  ' UNION ALL '
      ||  lv_sql_trni
      ||  ' UNION ALL '
      ||  lv_sql_adji
      ||  ' UNION ALL '
      ||  lv_sql_adji_po
      ||  ' UNION ALL '
      ||  lv_sql_adji_hm
      ||  ' UNION ALL '
      ||  lv_sql_adji_mv
      ||  ' UNION ALL '
      ||  lv_sql_adji_snt
      ||  ' UNION ALL '
      ||  lv_sql_prod
       ;
    lv_sql2 := ''
      ||  ' UNION ALL '
      ||  lv_sql_porc
      ||  ' UNION ALL '
      ||  lv_sql_porc_po
      ||  ' UNION ALL '
      ||  lv_sql_omsso
      ||  ' '
       ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql || lv_sql2 || lv_order_by;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) DEFAULT '*' ;            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**' ;           -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_locat_code           VARCHAR2(100) DEFAULT lc_break_init ;  -- �q�ɃR�[�h
    lv_crowd_code           VARCHAR2(100) DEFAULT lc_break_init ;  -- �Q�R�[�h
    lv_crowd_low            VARCHAR2(100) DEFAULT lc_break_init ;  -- �Q�R�[�h�i���j
    lv_crowd_mid            VARCHAR2(100) DEFAULT lc_break_init ;  -- �Q�R�[�h�i���j
    lv_crowd_high           VARCHAR2(100) DEFAULT lc_break_init ;  -- �Q�R�[�h�i��j
    lv_item_code            VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڃR�[�h
    lv_cost_kbn             VARCHAR2(100) DEFAULT lc_break_init ;  -- �����Ǘ��敪
    lv_column_no            VARCHAR2(100) DEFAULT lc_break_init ;  -- ���ڈʒu
    lv_col_name             VARCHAR2(100) DEFAULT lc_break_init ;  -- ���ڃ^�O
--
    -- �l�擾�p�p
    ln_unit_price           NUMBER        DEFAULT 0;               -- �P��
    ln_inv_qty              NUMBER        DEFAULT 0;               -- �݌ɐ���
    ln_inv_amt              NUMBER        DEFAULT 0;               -- �݌ɋ��z
    ln_first_inv_qty        NUMBER        DEFAULT 0;               -- �݌ɐ��ʁi����j
    ln_first_inv_amt        NUMBER        DEFAULT 0;               -- �݌ɋ��z�i����j
    ln_end_inv_qty          NUMBER        DEFAULT 0;               -- �݌ɐ��ʁi�����j
    ln_end_inv_amt          NUMBER        DEFAULT 0;               -- �݌ɋ��z�i�����j
--
    -- �v�Z�p
    ln_quantity             NUMBER        DEFAULT 0;               -- ����
    ln_qty_in               NUMBER        DEFAULT 0;               -- ���ʁi����j
    ln_qty_out              NUMBER        DEFAULT 0;               -- ���ʁi���o�j
    ln_amount               NUMBER        DEFAULT 0;               -- ���z
    ln_amt_in               NUMBER        DEFAULT 0;               -- ���z�i����j
    ln_amt_out              NUMBER        DEFAULT 0;               -- ���z�i���o�j
    ln_position             NUMBER        DEFAULT 0;               -- �|�W�V����
    ln_instr                NUMBER        DEFAULT 0;               -- ���ڔ���ؑֈʒu
--
    -- ���ڔ���p
    lb_trnsfr               BOOLEAN       DEFAULT FALSE;           -- �U�֍���
    lb_payout               BOOLEAN       DEFAULT FALSE;           -- ���o����
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
    ---------------------
    -- XML�^�O�}������
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR    --   �^�O�^�C�v  T:�^�O
                                                             -- D:�f�[�^
                                                             -- N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                             -- Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2                --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
      )
    IS
      -- *** ���[�J���ϐ� ***
      ln_xml_idx  NUMBER;
      ln_work     NUMBER;
      lv_work     VARCHAR2(32000);
--
    BEGIN
--
      IF (ic_type = gc_n) THEN
        --NULL�̏ꍇ�^�O�������Ȃ��Ή�
        IF (iv_value IS NULL) THEN
          RETURN;
        END IF;
--
        BEGIN
          ln_work := TO_NUMBER(iv_value);
        EXCEPTION
          WHEN INVALID_NUMBER OR VALUE_ERROR THEN
            RETURN;
        END;
      END IF;
--
      -- ���ڃ^�O�����u*_qty�v�܂��́u*_amt�v�̏ꍇ�A�o�͂��Ȃ�
      IF (iv_name = '*_qty') OR (TRIM(iv_name) = '*_amt') THEN
        RETURN;
      END IF;
--
      --�C���f�b�N�X
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      lv_work := iv_value;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(lv_work, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := lv_work ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
--
    END prc_set_xml ;
--
    ---------------------
    -- �W���P���擾
    ---------------------
    FUNCTION fnc_get_item_unit_price(
        in_pos   IN   NUMBER    --���R�[�h�z��ʒu
      ) RETURN NUMBER
    IS
--
    -- *** ���[�J���ϐ� ***
    ln_unit_price NUMBER DEFAULT 0;    --�����߂�l
--
    BEGIN
--
      --�����敪���W�������A�����敪�����ی���and���b�g�Ǘ����ΏۊO�̂Ƃ�
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- �W�������}�X�^���W���P�����擾
        BEGIN
          SELECT prc.stnd_unit_price as price
          INTO   ln_unit_price
          FROM   xxcmn_stnd_unit_price_v prc
          WHERE  prc.item_id    = gt_main_data(in_pos).item_id
            AND (prc.start_date_active IS NULL OR
                 prc.start_date_active  <= TRUNC(gt_main_data(in_pos).trans_date))
            AND (prc.end_date_active   IS NULL OR
                 prc.end_date_active    >= TRUNC(gt_main_data(in_pos).trans_date));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_unit_price :=  0;
        END;
        RETURN  ln_unit_price;
--
      --�����敪���W�������ȊO�̏ꍇ�AZero��ݒ�
      ELSE
        RETURN  0;
      END IF;
--
    END fnc_get_item_unit_price;
--
    --------------------------------------
    -- �i�ڂ̍݌ɁE���z�i���ےP���j���擾
    --------------------------------------
    PROCEDURE prc_get_inv_qty_amt(
        ir_param      IN     rec_param_data                     -- ���̓p�����[�^�Q
       ,in_pos        IN     NUMBER                             -- ���R�[�h�z��ʒu
       ,iv_year_month IN     VARCHAR2                           -- ������Ώ۔N��
       ,on_inv_qty    OUT    NUMBER                             -- ����
       ,on_inv_amt    OUT    NUMBER                             -- ���z�i���ےP���j
    )
    IS
      -- *** ���[�J���ϐ� ***
      ln_idx              NUMBER;           -- �ΏۃC���f�b�N�X
      ld_trn_start        VARCHAR2(20);     -- ������ΏۊJ�n��
      ld_trn_end          VARCHAR2(20);     -- ������ΏۊJ�n��
      ld_alv_start        VARCHAR2(20);     -- ���ד��ΏۊJ�n��
      ld_alv_end          VARCHAR2(20);     -- ���ד��ΏۊJ�n��
--
    BEGIN
--
      --��������O���i����j
      ln_idx := in_pos;  -- �����l
      IF (iv_year_month < ir_param.exec_year_month) THEN
        ld_trn_start := gv_exec_start_bef;
        ld_trn_end   := gv_exec_end_bef;
        ld_alv_start := gv_exec_start;
        ld_alv_end   := gv_exec_end;
      --������������i�����j
      ELSE
        IF (gt_main_data.COUNT > in_pos) THEN
          ln_idx := in_pos - 1;
        END IF;
        ld_trn_start := gv_exec_start;
        ld_trn_end   := gv_exec_end;
        ld_alv_start := gv_exec_start_aft;
        ld_alv_end   := gv_exec_end_aft;
      END IF;
--
      --�����敪���W�������A�����敪�����ی���and���b�g�Ǘ����ΏۊO�̂Ƃ�
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- ��VIEW(OMSO)��萔�ʂ��擾
        -- �������敪���W�������̂��߁A���z���Z�o���Ȃ�
        BEGIN
          SELECT
                 NVL(SUM(NVL(trn.trans_qty, 0)),0) as stock   -- �������
                ,0                                 as price   -- ���ےP��
          INTO   on_inv_qty
                ,on_inv_amt
          FROM  ic_tran_pnd               trn      -- �ۗ��݌Ƀg����
               ,xxcmn_rcv_pay_mst_omso_v  xrpmxv   --  ��VIW
          WHERE trn.trans_date >= FND_DATE.STRING_TO_DATE(ld_trn_start, gc_char_dt_format )
            AND trn.trans_date <= FND_DATE.STRING_TO_DATE(ld_trn_end,  gc_char_dt_format )
            AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(ld_alv_start, gc_char_dt_format )
            AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(ld_alv_end,  gc_char_dt_format )
            AND trn.doc_type            = gv_doc_type_omso                  --�����^�C�v
            AND trn.completed_ind       = 1                                 --�����敪
            AND trn.doc_type            = xrpmxv.doc_type                   --�����^�C�v
            AND trn.line_detail_id      = xrpmxv.doc_line
            AND trn.item_id             = gt_main_data(ln_idx).item_id
            AND ( (ir_param.print_kind <> gc_print_kind_locat)
               OR ( (ir_param.print_kind = gc_print_kind_locat)
                AND (trn.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
--
      --�����敪���W�������ȊO�̏ꍇ
      ELSE
        -- ��VIEW(OMSO)��萔�ʁE���z���擾
        BEGIN
          SELECT
                 NVL(SUM(NVL(trn.trans_qty, 0)),0) as stock       -- �������
                ,NVL(SUM(NVL(trn.trans_qty, 0) * NVL(xleiv.actual_unit_price, 0)),0)
                                                 as price          -- ���ےP��
          INTO   on_inv_qty
                ,on_inv_amt
          FROM ic_tran_pnd               trn      -- �ۗ��݌Ƀg����
              ,xxcmn_rcv_pay_mst_omso_v  xrpmxv   --  ��VIW
              ,xxcmn_lot_each_item_v     xleiv    -- ���b�g�ʕi�ڏ��
          WHERE trn.trans_date >= FND_DATE.STRING_TO_DATE(ld_trn_start, gc_char_dt_format )
            AND trn.trans_date <= FND_DATE.STRING_TO_DATE(ld_trn_end,  gc_char_dt_format )
            AND xrpmxv.arrival_date >= FND_DATE.STRING_TO_DATE(ld_alv_start, gc_char_dt_format )
            AND xrpmxv.arrival_date <= FND_DATE.STRING_TO_DATE(ld_alv_end,  gc_char_dt_format )
            AND trn.doc_type            = gv_doc_type_omso                  --�����^�C�v
            AND trn.completed_ind       = 1                                 --�����敪
            AND trn.doc_type            = xrpmxv.doc_type                   --�����^�C�v
            AND trn.line_detail_id      = xrpmxv.doc_line
            AND trn.item_id             = gt_main_data(ln_idx).item_id
            AND trn.item_id             = xleiv.item_id
            AND trn.lot_id              = xleiv.lot_id
            AND ( (ir_param.print_kind <> gc_print_kind_locat)
               OR ( (ir_param.print_kind = gc_print_kind_locat)
                AND (trn.whse_code       = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
      END IF;
--
    END prc_get_inv_qty_amt;
--
    ------------------------------------------------
    -- �i�ڂ̌���E�����݌ɁE���z�i���ےP���j���擾
    ------------------------------------------------
    PROCEDURE prc_get_fst_end_inv_qty_amt(
        ir_param      IN   rec_param_data    -- ���̓p�����[�^�Q
       ,in_pos        IN   NUMBER            -- ���R�[�h�z��ʒu
       ,iv_year_month IN   VARCHAR2          -- �Ώ۔N��
       ,on_inv_qty    OUT  NUMBER            -- ����
       ,on_inv_amt    OUT  NUMBER            -- ���z�i���ےP���j
      )
    IS
      -- *** ���[�J���ϐ� ***
      ln_idx  NUMBER;
--
    BEGIN
--
      -- �ΏۃC���f�b�N�X���擾
      ln_idx := in_pos;  -- �����l
      IF (iv_year_month = ir_param.exec_year_month) AND (gt_main_data.COUNT > in_pos) THEN
        -- ����
        ln_idx := in_pos - 1;
      END IF;
--
      --�����敪���W�������A�����敪�����ی���and���b�g�Ǘ����ΏۊO�̂Ƃ�
      IF  (   (gt_main_data(in_pos).cost_kbn = gc_cost_st)
           OR (    (gt_main_data(in_pos).cost_kbn = gc_cost_ac)
               AND (gt_main_data(in_pos).lot_ctl  = gn_lot_ctl_n) ) )
      THEN
        -- �����݌ɂ�萔�ʂ��擾
        BEGIN
          SELECT NVL(SUM(NVL(stc.monthly_stock, 0)),0) as stock
                ,0                                     as price
          INTO   on_inv_qty
                ,on_inv_amt
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.item_id   = gt_main_data(ln_idx).item_id
          AND    stc.invent_ym = iv_year_month
          AND ( (ir_param.print_kind <> gc_print_kind_locat)
             OR ( (ir_param.print_kind = gc_print_kind_locat)
              AND (stc.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
--
        -- �������敪���W�������̂��߁A���z���Z�o���Ȃ�
--
      --�����敪���W�������ȊO�̏ꍇ
      ELSE
        -- �����݌ɂ�萔�ʁE���z���擾
        BEGIN
          SELECT NVL(SUM(NVL(stc.monthly_stock, 0)),0) as stock
                ,NVL(SUM(NVL(stc.monthly_stock, 0) * NVL(xleiv.actual_unit_price, 0)),0)
                                                       as price
          INTO   on_inv_qty
                ,on_inv_amt
          FROM   xxinv_stc_inventory_month_stck stc
                ,xxcmn_lot_each_item_v          xleiv    -- ���b�g�ʕi�ڏ��
          WHERE  stc.item_id   = gt_main_data(ln_idx).item_id
          AND    stc.invent_ym = iv_year_month
          AND    stc.item_id   = xleiv.item_id
          AND    stc.lot_id    = xleiv.lot_id
          AND ( (ir_param.print_kind <> gc_print_kind_locat)
             OR ( (ir_param.print_kind = gc_print_kind_locat)
              AND (stc.whse_code = gt_main_data(ln_idx).locat_code)));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty :=  0;
            on_inv_amt :=  0;
        END;
      END IF;
--
    END prc_get_fst_end_inv_qty_amt;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'user_info');
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ���[���
    prc_set_xml('D', 'out_div', ir_param.print_kind);
    prc_set_xml('D', 'out_div_name', gv_print_class_name, 20);
    -- �����N��
    prc_set_xml('D', 'exec_year', SUBSTR(ir_param.exec_year_month, 1, 4) );
    prc_set_xml('D', 'exec_month', TO_CHAR(SUBSTR(ir_param.exec_year_month, 5, 2),'00') );
    -- ���i�敪
    prc_set_xml('D', 'prod_div', ir_param.goods_class);
    prc_set_xml('D', 'prod_div_name', gv_goods_class_name, 20);
    -- �i�ڋ敪
    prc_set_xml('D', 'item_div', ir_param.item_class);
    prc_set_xml('D', 'item_div_name', gv_item_class_name, 20);
    -- �Q���
    prc_set_xml('D', 'crowd_div', ir_param.crowd_kind);
    prc_set_xml('D', 'crowd_div_name', gv_crowd_kind_name, 20);
--
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gv_report_id);
    -- ���{��
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- �S������
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- �S���Җ�
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
--
    -- �q�ɃR�[�h���w�肳��Ă���ꍇ
    IF (ir_param.locat_code  IS NOT NULL) THEN
      -- �q�Ɍv�o�͂Ȃ�
      prc_set_xml('D', 'locat_sum', '1');
    END IF;
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- �q�ɂk�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_locat');
    -- ���[�敪���u�i�ڕʁv�̏ꍇ
    IF (ir_param.print_kind = gc_print_kind_item) THEN
      -- -----------------------------------------------------
      -- �q�ɂf�J�n�^�O�o��
      -- -----------------------------------------------------
      prc_set_xml('T', 'g_locat');
      -- �|�W�V����
      ln_position := ln_position + 1;
      prc_set_xml('D', 'position', TO_CHAR(ln_position));
--
      -- -----------------------------------------------------
      -- �L�[�u���C�N���̏�������
      -- -----------------------------------------------------
      -- �L�[�u���C�N�p�ϐ��ޔ�
      lv_locat_code := lc_break_null ;
      lv_crowd_high := lc_break_init ;
      -- -----------------------------------------------------
      -- ��Q�R�[�h�k�f�J�n�^�O�o��
      -- -----------------------------------------------------
      prc_set_xml('T', 'lg_crowd_high');
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- �q�ɃR�[�h�u���C�N
      -- =====================================================
      -- ���[��ʂ��u�q�ɁE�i�ڕʁv�őq�ɃR�[�h���؂�ւ�����ꍇ
      IF   ( ir_param.print_kind = gc_print_kind_locat )
       AND ( NVL( gt_main_data(i).locat_code, lc_break_null ) <> lv_locat_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_locat_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_mid');
          ------------------------------
          -- ��Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_high');
          ------------------------------
          -- ��Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_high');
          ------------------------------
          -- �q�ɃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_locat');
        END IF ;
--
        -- -----------------------------------------------------
        -- �q�ɃR�[�h�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_locat');
        -- -----------------------------------------------------
        -- �q�ɃR�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �|�W�V����
        ln_position := ln_position + 1;
        prc_set_xml('D', 'position', TO_CHAR(ln_position));
        -- �q�ɃR�[�h
        prc_set_xml('D', 'locat_code', gt_main_data(i).locat_code);
        -- �q�ɖ�
        prc_set_xml('D', 'locat_name', gt_main_data(i).locat_name, 20);
        -- -----------------------------------------------------
        -- ��Q�R�[�h�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'lg_crowd_high');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_locat_code := NVL( gt_main_data(i).locat_code, lc_break_null )  ;
        lv_crowd_high := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ��Q�R�[�h�u���C�N
      -- =====================================================
      -- ��Q�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).crowd_high, lc_break_null ) <> lv_crowd_high ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_crowd_high <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_mid');
          ------------------------------
          -- ��Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_high');
        END IF ;
--
        ------------------------------
        -- ��Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_high');
        -- -----------------------------------------------------
        -- ��Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ��Q�R�[�h
        prc_set_xml('D', 'crowd_high', gt_main_data(i).crowd_high);
        ------------------------------
        -- ���Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd_mid');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_crowd_high := NVL( gt_main_data(i).crowd_high, lc_break_null ) ;
        lv_crowd_mid  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���Q�R�[�h�u���C�N
      -- =====================================================
      -- ���Q�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).crowd_mid, lc_break_null ) <> lv_crowd_mid ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_crowd_mid <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_low');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_mid');
        END IF ;
--
        ------------------------------
        -- ���Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_mid');
        -- -----------------------------------------------------
        -- ���Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���Q�R�[�h
        prc_set_xml('D', 'crowd_mid', gt_main_data(i).crowd_mid);
        ------------------------------
        -- ���Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd_low');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_crowd_mid := NVL( gt_main_data(i).crowd_mid, lc_break_null ) ;
        lv_crowd_low  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���Q�R�[�h�u���C�N
      -- =====================================================
      -- ���Q�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).crowd_low, lc_break_null ) <> lv_crowd_low ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_crowd_low <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_dtl');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_low');
        END IF ;
--
        ------------------------------
        -- ���Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_low');
        -- -----------------------------------------------------
        -- ���Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���Q�R�[�h
        prc_set_xml('D', 'crowd_low', gt_main_data(i).crowd_low);
        ------------------------------
        -- �Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd_dtl');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_crowd_low  := NVL( gt_main_data(i).crowd_low, lc_break_null ) ;
        lv_crowd_code := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- �Q�R�[�h�u���C�N
      -- =====================================================
      -- �Q�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).crowd_code, lc_break_null ) <> lv_crowd_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_crowd_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_dtl');
        END IF ;
--
        ------------------------------
        -- �Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_dtl');
        -- -----------------------------------------------------
        -- �Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �Q�R�[�h
        prc_set_xml('D', 'crowd_dtl', gt_main_data(i).crowd_code);
        ------------------------------
        -- ���i�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_item');
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_crowd_code := NVL( gt_main_data(i).crowd_code, lc_break_null ) ;
        lv_item_code  := lc_break_init ;
        lv_cost_kbn   := lc_break_init ;
--
        -- �v�Z���ڏ�����
        ln_unit_price    := 0;
        ln_inv_qty       := 0;
        ln_inv_amt       := 0;
        ln_first_inv_qty := 0;
        ln_first_inv_amt := 0;
        ln_end_inv_qty   := 0;
        ln_end_inv_amt   := 0;
--
      END IF ;
--
      -- =====================================================
      -- �i�ڃR�[�h�u���C�N
      -- =====================================================
      -- �i�ڃR�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).item_code, lc_break_null ) <> lv_item_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�̓^�O���o�͂��Ȃ��B
        IF ( lv_item_code <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
--
          -- -----------------------------------------------------
          -- �����f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ����
          ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
          prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
          prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- -----------------
          -- ��VIEW���擾
          -- -----------------
          prc_get_inv_qty_amt(ir_param, i, ir_param.exec_year_month, ln_inv_qty, ln_inv_amt);
--
          -- -----------------------------------------------------
          -- �I���E���كf�[�^�^�O�o��
          -- -----------------------------------------------------
          prc_get_fst_end_inv_qty_amt(ir_param, i, ir_param.exec_year_month,
                                                ln_end_inv_qty, ln_end_inv_amt);
          IF (ln_end_inv_qty = 0) THEN
            -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
            prc_set_xml('N', 'inv_qty'  , '0');
            prc_set_xml('N', 'inv_amt'  , '0');
            prc_set_xml('N', 'quantity' , '0');
            prc_set_xml('N', 'amount'   , '0');
          ELSE
            -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
            -- �I������
            ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
            prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
            -- �I�����z
            IF (lv_cost_kbn = gc_cost_st ) THEN
              -- �����Ǘ��敪���u�W�������v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
            ELSE
              -- �����Ǘ��敪���u���ی����v�̏ꍇ
              ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
            END IF;
            prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
            -- ���ِ���
            ln_quantity := ln_quantity - ln_end_inv_qty;
            prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
            -- ���ً��z
            ln_amount := ln_amount - ln_end_inv_amt ;
            prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
          END IF;
--
          ------------------------------
          -- �i�ڃR�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
        END IF ;
--
        ------------------------------
        -- �i�ڃR�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_item');
        -- -----------------------------------------------------
        -- �i�ڃR�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �i�ڃR�[�h
        prc_set_xml('D', 'item_code', gt_main_data(i).item_code);
        -- �i�ږ���
        prc_set_xml('D', 'item_name', gt_main_data(i).item_name, 20);
--
        -- -----------------------------------------------------
        -- �i�ڒP�ʂł̍��ڎ擾
        -- -----------------------------------------------------
        -- �P��
        ln_unit_price := fnc_get_item_unit_price(i) ;
--
        -- -----------------
        -- ��VIEW���擾
        -- -----------------
        prc_get_inv_qty_amt(ir_param, i, gv_exec_year_month_bef, ln_inv_qty, ln_inv_amt);
--
        -- -----------------------------------------------------
        -- ����f�[�^�^�O�o��
        -- -----------------------------------------------------
        prc_get_fst_end_inv_qty_amt(ir_param, i, gv_exec_year_month_bef,
                                              ln_first_inv_qty, ln_first_inv_amt);
        -- ����
        ln_first_inv_qty := ln_first_inv_qty + ln_inv_qty;
        prc_set_xml('Z', 'first_inv_qty' , TO_CHAR(ln_first_inv_qty) );
        -- ���z
        IF (NVL( gt_main_data(i).cost_kbn, lc_break_null ) = gc_cost_st ) THEN
          -- �����Ǘ��敪���u�W�������v�̏ꍇ
          ln_first_inv_amt := (ln_first_inv_qty + ln_inv_qty) * ln_unit_price;
        ELSE
          -- �����Ǘ��敪���u���ی����v�̏ꍇ
          IF (gt_main_data(i).lot_ctl = gn_lot_ctl_y) THEN
            ln_first_inv_amt := ln_first_inv_amt + ln_inv_amt;
          ELSE
            ln_first_inv_amt := (ln_first_inv_qty + ln_inv_qty) * ln_unit_price;
          END IF;
        END IF;
        prc_set_xml('Z', 'first_inv_amt' , TO_CHAR(ln_first_inv_amt) );
--
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code   := NVL( gt_main_data(i).item_code, lc_break_null ) ;
        lv_cost_kbn    := NVL( gt_main_data(i).cost_kbn, lc_break_null ) ;
        IF ( (lv_cost_kbn = gc_cost_ac) AND (gt_main_data(i).lot_ctl = gn_lot_ctl_n) ) THEN
          lv_cost_kbn  := gc_cost_st;
        END IF;
        lv_column_no   := lc_break_init ;
--
        -- �v�Z���ڏ�����
        ln_quantity := 0;
        ln_amount   := 0;
        ln_qty_in   := 0;
        ln_qty_out  := 0;
        ln_amt_in   := 0;
        ln_amt_out  := 0;
--
      END IF ;
--
      -- =====================================================
      -- ���ڈʒu�u���C�N
      -- =====================================================
      -- ���ڈʒu���؂�ւ�����ꍇ
      IF (NVL( gt_main_data(i).column_no, lc_break_null ) <> lv_column_no ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͖��׃^�O���o�͂��Ȃ��B
        IF ( lv_column_no <> lc_break_init ) THEN
          -- -----------------------------------------------------
          -- ���׃f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
            ln_amount := ln_unit_price * ln_quantity;
          END IF;
          -- ���o���ڂ̏ꍇ
          IF (lb_payout = TRUE) THEN
            ln_quantity := ln_quantity * -1;
            ln_amount   := ln_amount * -1;
          END IF;
          -- ����
          prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- ���z
          prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
          -- ���ʁE���z���W�v�i�i�ڒP�ʁj
          IF (lb_payout = FALSE) THEN
            -- ���
            ln_qty_in := ln_qty_in + ln_quantity;
            ln_amt_in := ln_amt_in + ln_amount;
          ELSE
            -- ���o
            ln_qty_out := ln_qty_out + ln_quantity;
            ln_amt_out := ln_amt_out + ln_amount;
          END IF;
        END IF ;
--
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_column_no   := NVL( gt_main_data(i).column_no, lc_break_null ) ;
--
        -- �v�Z���ڏ�����
        ln_quantity := 0;
        ln_amount   := 0;
        lv_col_name := lc_break_init;
--
        -- ���ڔ��菉����
        lb_trnsfr   := FALSE;
        lb_payout   := FALSE;
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      CASE lv_column_no
        -- **�y����z**
        -- �d��
        WHEN gc_col_no_po THEN
          lv_col_name := 'po';
        -- �
        WHEN gc_col_no_wrap THEN
          lv_col_name := 'wrap';
        -- �Z�b�g
        WHEN gc_col_no_set THEN
          lv_col_name := 'set';
        -- ����
        WHEN gc_col_no_oki THEN
          lv_col_name := 'okinawa';
        -- �U�֓���
        WHEN gc_col_no_trnsfr THEN
          lv_col_name := 'trnsfr';
          lb_trnsfr   := TRUE;
        -- �Ήc�P
        WHEN gc_col_no_acct_1 THEN
          lv_col_name := 'acct_1';
          lb_trnsfr   := TRUE;
        -- �Ήc�Q
        WHEN gc_col_no_acct_2 THEN
          lv_col_name := 'acct_2';
          lb_trnsfr   := TRUE;
        -- �h�����N�M�t�g
        WHEN gc_col_no_guift THEN
          lv_col_name := 'guift';
          lb_trnsfr   := TRUE;
        -- �q��
        WHEN gc_col_no_locat_chg THEN
          lv_col_name := 'locat_chg';
        -- �ԕi
        WHEN gc_col_no_ret_goods THEN
          lv_col_name := 'ret_goods';
        -- ���̑�
        WHEN gc_col_no_other THEN
          lv_col_name := 'other';
        -- **�y���o�z**
        -- �Z�b�g
        WHEN gc_col_no_out_set THEN
          lv_col_name := 'out_set';
          lb_payout   := TRUE;
        -- �ԕi������
        WHEN gc_col_no_out_mtrl THEN
          lv_col_name := 'out_mtrl';
          lb_payout   := TRUE;
        -- ��̔����i��
        WHEN gc_col_no_out_dismnt THEN
          lv_col_name := 'out_dismnt';
          lb_payout   := TRUE;
        -- �L��
        WHEN gc_col_no_out_pay THEN
          lv_col_name := 'out_pay';
          lb_payout   := TRUE;
        -- �U�֗L��
        WHEN gc_col_no_out_trnsfr THEN
          lv_col_name := 'out_trnsfr';
          lb_payout   := TRUE;
          lb_trnsfr   := TRUE;
        -- ���_
        WHEN gc_col_no_out_point THEN
          lv_col_name := 'out_point';
          lb_payout   := TRUE;
        -- �h�����N�M�t�g
        WHEN gc_col_no_out_guift THEN
          lv_col_name := 'out_guift';
          lb_payout   := TRUE;
          lb_trnsfr   := TRUE;
        -- ���̑�
        WHEN gc_col_no_out_other THEN
          lv_col_name := 'out_other';
          lb_payout   := TRUE;
        ELSE
          lv_col_name := lc_break_init;
      END CASE;
--
      -- ���ږ��������l�ȊO
      IF (lv_col_name <> lc_break_init) THEN
        -- �U�֍��ڂ̏ꍇ
        IF (lb_trnsfr = TRUE) THEN
          -- ���ʉ��Z
          ln_quantity := ln_quantity + (NVL( gt_main_data(i).trans_qty, 0 )
                                        * NVL( gt_main_data(i).rcv_pay_div, 0));
          -- ���z���Z�i�����Ǘ��敪���u���ی����v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            ln_amount := ln_amount + (NVL(gt_main_data(i).trans_qty,0)
                                      * NVL(gt_main_data(i).actual_unit_price,0)
                                      * NVL( gt_main_data(i).rcv_pay_div, 0));
          END IF;
        ELSE
          -- ���ʉ��Z
          ln_quantity := ln_quantity + NVL( gt_main_data(i).trans_qty, 0 );
          -- ���z���Z�i�����Ǘ��敪���u���ی����v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            ln_amount := ln_amount + (NVL(gt_main_data(i).trans_qty,0)
                                      * NVL(gt_main_data(i).actual_unit_price,0));
          END IF;
        END IF;
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
--
    -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
    IF (lv_cost_kbn = gc_cost_st ) THEN
      ln_amount := ln_unit_price * ln_quantity;
    END IF;
    -- ���o���ڂ̏ꍇ
    IF (lb_payout = TRUE) THEN
      ln_quantity := ln_quantity * -1;
      ln_amount   := ln_amount * -1;
    END IF;
    -- ����
    prc_set_xml('Z', lv_col_name || '_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
    -- ���z
    prc_set_xml('Z', lv_col_name || '_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
    -- ���ʁE���z���W�v�i�i�ڒP�ʁj
    IF (lb_payout = FALSE) THEN
      -- ���
      ln_qty_in := ln_qty_in + ln_quantity;
      ln_amt_in := ln_amt_in + ln_amount;
    ELSE
      -- ���o
      ln_qty_out := ln_qty_out + ln_quantity;
      ln_amt_out := ln_amt_out + ln_amount;
    END IF;
--
    -- -----------------------------------------------------
    -- �����f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- ����
    ln_quantity := ln_first_inv_qty + ln_qty_in - ln_qty_out;
    prc_set_xml('Z', 'end_inv_qty' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
    -- ���z
    ln_amount := ln_first_inv_amt + ln_amt_in - ln_amt_out;
    prc_set_xml('Z', 'end_inv_amt' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
--
    -- -----------------
    -- ��VIEW���擾
    -- -----------------
    prc_get_inv_qty_amt(ir_param, gt_main_data.COUNT, ir_param.exec_year_month,
                        ln_inv_qty, ln_inv_amt);
--
    -- -----------------------------------------------------
    -- �I���E���كf�[�^�^�O�o��
    -- -----------------------------------------------------
    prc_get_fst_end_inv_qty_amt(ir_param, gt_main_data.COUNT, ir_param.exec_year_month,
                                          ln_end_inv_qty, ln_end_inv_amt);
    IF (ln_end_inv_qty = 0) THEN
      -- �݌ɐ��ʂ��m�肵�Ă��Ȃ��ꍇ
      prc_set_xml('N', 'inv_qty'  , '0');
      prc_set_xml('N', 'inv_amt'  , '0');
      prc_set_xml('N', 'quantity' , '0');
      prc_set_xml('N', 'amount'   , '0');
    ELSE
      -- �݌ɐ��ʂ��m�肵�Ă���ꍇ
      -- �I������
      ln_end_inv_qty := ln_end_inv_qty + ln_inv_qty;
      prc_set_xml('N', 'inv_qty' ,TO_CHAR(ROUND(ln_end_inv_qty, gn_quantity_decml)));
      -- �I�����z
      IF (lv_cost_kbn = gc_cost_st ) THEN
        -- �����Ǘ��敪���u�W�������v�̏ꍇ
        ln_end_inv_amt := ln_end_inv_qty * ln_unit_price;
      ELSE
        -- �����Ǘ��敪���u���ی����v�̏ꍇ
        ln_end_inv_amt := ln_end_inv_amt + ln_inv_amt;
      END IF;
      prc_set_xml('N', 'inv_amt' ,TO_CHAR(ROUND(ln_end_inv_amt, gn_amount_decml )));
      -- ���ِ���
      ln_quantity := ln_quantity - ln_end_inv_qty;
      prc_set_xml('N', 'quantity' ,TO_CHAR(ROUND(ln_quantity, gn_quantity_decml )));
      -- ���ً��z
      ln_amount := ln_amount - ln_end_inv_amt ;
      prc_set_xml('N', 'amount' ,TO_CHAR(ROUND(ln_amount, gn_amount_decml )));
    END IF;
    ------------------------------
    -- �i�ڃR�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_item');
    ------------------------------
    -- �i�ڃR�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- �Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_dtl');
    ------------------------------
    -- �Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_dtl');
    ------------------------------
    -- ���Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_low');
    ------------------------------
    -- ���Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_low');
    ------------------------------
    -- ���Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_mid');
    ------------------------------
    -- ���Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_mid');
    ------------------------------
    -- ��Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_high');
    ------------------------------
    -- ��Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_high');
    ------------------------------
    -- �q�ɃR�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_locat');
    ------------------------------
    -- �q�ɃR�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_locat');
    ------------------------------
    -- �f�[�^�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/data_info');
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_exec_year_month    IN     VARCHAR2         --   01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         --   02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   03 : �i�ڋ敪
     ,iv_print_kind         IN     VARCHAR2         --   04 : ���[���
     ,iv_locat_code         IN     VARCHAR2         --   05 : �q�ɃR�[�h
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �Q���
     ,iv_crowd_code         IN     VARCHAR2         --   07 : �Q�R�[�h
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : �o���Q�R�[�h
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gv_report_id                    := 'XXCMN770002T' ;      -- ���[ID
    gd_exec_date                    := SYSDATE ;             -- ���{��
    -- �p�����[�^�i�[
    lr_param_rec.exec_year_month    := iv_exec_year_month;   -- �����N��
    lr_param_rec.goods_class        := iv_goods_class ;      -- ���i�敪
    lr_param_rec.item_class         := iv_item_class ;       -- �i�ڋ敪
    lr_param_rec.print_kind         := iv_print_kind;        -- ���[�敪
    lr_param_rec.locat_code         := iv_locat_code;        -- �q�ɃR�[�h
    lr_param_rec.crowd_kind         := iv_crowd_kind;        -- �Q���
    lr_param_rec.crowd_code         := iv_crowd_code;        -- �Q�R�[�h
    lr_param_rec.acct_crowd_code    := iv_acct_crowd_code;   -- �o���S�R�[�h
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF  (lv_retcode = gv_status_error)
     OR (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                       <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         --   02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   03 : �i�ڋ敪
     ,iv_print_kind         IN     VARCHAR2         --   04 : ���[���
     ,iv_locat_code         IN     VARCHAR2         --   05 : �q�ɃR�[�h
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �Q���
     ,iv_crowd_code         IN     VARCHAR2         --   07 : �Q�R�[�h
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : �o���Q�R�[�h
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_exec_year_month   => iv_exec_year_month   --   01 : �����N��
       ,iv_goods_class       => iv_goods_class       --   02 : ���i�敪
       ,iv_item_class        => iv_item_class        --   03 : �i�ڋ敪
       ,iv_print_kind        => iv_print_kind        --   04 : ���[���
       ,iv_locat_code        => iv_locat_code        --   05 : �q�ɃR�[�h
       ,iv_crowd_kind        => iv_crowd_kind        --   06 : �Q���
       ,iv_crowd_code        => iv_crowd_code        --   07 : �Q�R�[�h
       ,iv_acct_crowd_code   => iv_acct_crowd_code   --   08 : �o���Q�R�[�h
       ,ov_errbuf            => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn770002c ;
/
