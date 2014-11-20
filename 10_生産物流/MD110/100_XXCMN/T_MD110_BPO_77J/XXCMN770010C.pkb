create or replace PACKAGE BODY xxcmn770010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770010C(body)
 * Description      : �W����������\
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77J)
 * Version          : 1.20
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  prc_set_xml               PROCEDRUE : �w�l�k�p�z��Ɋi�[����B
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(J-1)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/14    1.0   N.Chinen         �V�K�쐬
 *  2008/05/13    1.1   N.Chinen         ���ד��Ńf�[�^�𒊏o����悤�C���B
 *  2008/05/16    1.2   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[��
 *                                       �Ȃ�_���C���B
 *  2008/06/12    1.3   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/19    1.4   Y.Ishikawa       ����敪���p�p�A���{�Ɋւ��ẮA�󕥋敪���|���Ȃ�
 *  2008/06/19    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.7   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *  2008/08/07    1.8   Y.Majikina       �Q�Ƃ���VIEW��XXCMN_RCV_PAY_MST_PORC_RMA_V ��
 *                                       XXCMN_RCV_PAY_MST_PORC_RMA10_V�֕ύX
 *  2008/08/28    1.9   A.Shiina         T_TE080_BPO_770 �w�E19�Ή�
 *  2008/10/23    1.10  N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/11/14    1.11  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.12  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#215�Ή�
 *  2008/12/02    1.14  N.Yoshida        �{��#345�Ή�(�U�֓��ɁA�Ήc�P�A�Ήc�Q�ǉ��Ή�)
 *                                       �{��#385�Ή�
 *  2008/12/06    1.15  T.Miyata         �{��#495�Ή�
 *  2008/12/06    1.16  T.Miyata         �{��#498�Ή�
 *  2008/12/07    1.17  N.Yoshida        �{��#496�Ή�
 *  2008/12/11    1.18  A.Shiina         �{��#580�Ή�
 *  2008/12/13    1.19  T.Ohashi         �{��#580�Ή�
 *  2008/12/14    1.20  N.Yoshida        �{�ԏ�Q669�Ή�
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770010C' ;     -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '�W����������\' ;   -- ���[��
  gc_first_date             CONSTANT VARCHAR2(2) := '01'; -- ������:01��
--
  ------------------------------
  -- �N�C�b�N�R�[�h�֘A
  ------------------------------
  gc_lookup_type             CONSTANT VARCHAR2(40) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class        CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class         CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- ����敪��
  ------------------------------
  gv_haiki                   CONSTANT VARCHAR2(100) := '�p�p' ;
  gv_mihon                   CONSTANT VARCHAR2(100) := '���{' ;
  gv_d_name_trn_rcv          CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֗L��_���';
  gv_d_name_item_trn_rcv     CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '���i�U�֗L��_���';
  gv_d_name_trn_ship_rcv_gen CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֏o��_���_��';
  gv_d_name_trn_ship_rcv_han CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֏o��_���_��';
  gc_rcv_pay_div_adj         CONSTANT VARCHAR2(2) := '-1' ;  --����
--
   ------------------------------
  -- �Q���
  ------------------------------
  gc_crowd_kind           CONSTANT VARCHAR2(1) := '3';    --�Q��
  gc_crowd_acct_kind      CONSTANT VARCHAR2(1) := '4';    --�o���Q��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_char_y_format        CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_format          CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_dt_format       CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS' ;
  gc_char_ym_format       CONSTANT VARCHAR2(30) := 'YYYY"�N"MM"��"';
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_d                   CONSTANT VARCHAR2(1) := 'D';
  gc_n                   CONSTANT VARCHAR2(1) := 'N';
  gc_t                   CONSTANT VARCHAR2(1) := 'T';
  gc_z                   CONSTANT VARCHAR2(1) := 'Z';
--
  ------------------------------
  -- ���l�E���z�����_�ʒu
  ------------------------------
  gn_qty_dec             CONSTANT NUMBER      := 3;
--
  gn_one                 CONSTANT NUMBER      := 1   ;
  gn_two                 CONSTANT NUMBER      := 2   ;
--
  ------------------------------
  -- ���ڈʒu���f
  ------------------------------
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
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_date_from      VARCHAR2(6)                              -- �����N��(from,'YYYYMM'�`��)
     ,exec_date_to        VARCHAR2(6)                              -- �����N��(to,  'YYYYMM'�`��)
     ,goods_class         mtl_categories_b.segment1%TYPE           -- ���i�敪
     ,item_class          mtl_categories_b.segment1%TYPE           -- �i�ڋ敪
     ,rcv_pay_div         xxcmn_rcv_pay_mst_prod_v.rcv_pay_div%TYPE -- �󕥋敪
     ,crowd_kind          fnd_lookup_values.meaning%TYPE           -- �Q���
     ,crowd_code          mtl_categories_b.segment1%TYPE           -- �Q�R�[�h
     ,acct_crowd_code     mtl_categories_b.segment1%TYPE           -- �o���Q�R�[�h
    );
--
  -- �󕥎c���\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD(
      item_code             ic_item_mst_b.item_no%TYPE              -- �i�ڃR�[�h
     ,item_name             xxcmn_item_mst_b.item_short_name%TYPE   -- �i�ږ���
     ,unit_price            cm_cmpt_dtl.cmpnt_cost%TYPE             -- �W������
     ,raw_material_cost     cm_cmpt_dtl.cmpnt_cost%TYPE             -- ������
     ,agein_cost            cm_cmpt_dtl.cmpnt_cost%TYPE             -- �Đ���
     ,material_cost         cm_cmpt_dtl.cmpnt_cost%TYPE             -- ���ޔ�
     ,pack_cost             cm_cmpt_dtl.cmpnt_cost%TYPE             -- ���
     ,other_expense_cost    cm_cmpt_dtl.cmpnt_cost%TYPE             -- ���̑��o��
     ,crowd_code            mtl_categories_b.segment1%TYPE          -- �Q�R�[�h
     ,crowd_low             mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i���j
     ,crowd_mid             mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i���j
     ,crowd_high            mtl_categories_b.segment1%TYPE          -- �Q�R�[�h�i��j
     ,trans_qty             ic_tran_pnd.trans_qty%TYPE              -- �������
    );
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
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE; -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;      -- �S����
  gv_print_class_name       fnd_lookup_values.meaning%TYPE;               -- ���[��ʖ�
  gv_goods_class_name       mtl_categories_tl.description%TYPE;           -- ���i�敪��
  gv_rcv_pay_div_name       fnd_lookup_values.meaning%TYPE;               -- �󕥋敪��
  gv_crowd_kind_name        mtl_categories_tl.description%TYPE;           -- �Q��ʖ�
--
  ------------------------------
  -- �����擾�p
  ------------------------------
  gv_exec_year_month_bef    VARCHAR2(6);       -- �����N���̑O��
  gd_exec_start             DATE;             -- �����N���̊J�n��
  gd_exec_end               DATE;             -- �����N���̏I����
  gv_exec_start             VARCHAR2(20);     -- �����N���̊J�n��
  gv_exec_end               VARCHAR2(20);     -- �����N���̏I����
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
    -- �v���O������
    cv_prg_name           CONSTANT VARCHAR2(100) := 'prc_initialize';
    --�󕥋敪
    cv_div_type           CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_NEW_ACCOUNT_DIV';
    --�����N��(FROM)�̃G���[
    cv_err_exec_date_from CONSTANT VARCHAR2(20) := '�����N��(FROM)';
    --�����N��(TO)�̃G���[
    cv_err_exec_date_to   CONSTANT VARCHAR2(20) := '�����N��(TO)';
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
    lc_f_time          CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time          CONSTANT VARCHAR2(10) := ' 23:59:59';
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
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
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
    -- �󕥋敪�擾
    -- ====================================================
    BEGIN
      SELECT xlvv.meaning
      INTO   gv_rcv_pay_div_name
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = cv_div_type
      AND    lookup_code = ir_param.rcv_pay_div
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- ���t���擾
    -- ====================================================
    -- �����N���E�J�n��
    gd_exec_start := FND_DATE.STRING_TO_DATE(ir_param.exec_date_from, gc_char_y_format);
    gv_exec_start := TO_CHAR(gd_exec_start, gc_char_d_format) || lc_f_time;
    -- �G���[����
    IF ( gd_exec_start IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_err_exec_date_from
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_date_from ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
    -- �����N���E�I����
    gd_exec_end   := LAST_DAY(FND_DATE.STRING_TO_DATE(ir_param.exec_date_to, gc_char_y_format));
    gv_exec_end   := TO_CHAR(gd_exec_end, gc_char_d_format) || lc_f_time;
    -- �G���[����
    IF ( gd_exec_end IS NULL ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg ( gc_application
                                             ,'APP-XXCMN-10155'
                                             ,'ERROR_PARAM'
                                             ,cv_err_exec_date_to
                                             ,'ERROR_VALUE'
                                             ,ir_param.exec_date_to ) ;
      lv_retcode  := gv_status_error;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
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
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(J-1)
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
    -- �e�����^�C�v
    cv_doc_type_xfer          CONSTANT VARCHAR2(4) := 'XFER';
    cv_doc_type_trni          CONSTANT VARCHAR2(4) := 'TRNI';
    cv_doc_type_prod          CONSTANT VARCHAR2(4) := 'PROD';
    cv_doc_type_adji          CONSTANT VARCHAR2(4) := 'ADJI';
    cv_doc_type_porc          CONSTANT VARCHAR2(4) := 'PORC';
    cv_doc_type_omso          CONSTANT VARCHAR2(4) := 'OMSO';
    -- �����t���O
    cv_completed_ind          CONSTANT VARCHAR2(4) := '1';
    -- �݌ɒ������R�R�[�h
-- 2008/10/24 v1.10 ADD START
    gv_reason_code_trni       CONSTANT VARCHAR2(4) := 'X122';
    cv_reason_code_mokusi_u   CONSTANT VARCHAR2(4) := 'X943'; -- �َ��i�ڎ��
    cv_reason_code_sonota_u   CONSTANT VARCHAR2(4) := 'X950'; -- ���̑����
-- 2008/10/24 v1.10 ADD END
    cv_reason_code_henpin     CONSTANT VARCHAR2(4) := 'X201'; -- �d����ԕi
    cv_reason_code_hamaoka    CONSTANT VARCHAR2(4) := 'X988'; -- �l�����
    cv_reason_code_aitezaiko  CONSTANT VARCHAR2(4) := 'X977'; -- �����݌�
    cv_reason_code_idouteisei CONSTANT VARCHAR2(4) := 'X123'; -- �ړ����ђ���
    cv_reason_code_mokusi     CONSTANT VARCHAR2(4) := 'X942'; -- �َ��i�ڎ�
    cv_reason_code_sonota     CONSTANT VARCHAR2(4) := 'X951'; -- ���̑���
    -- �����Ǘ��敪
    cv_cost_manage_code       CONSTANT VARCHAR2(4) := '1'; -- �W������
    -- ���{
    cv_jpn                    CONSTANT VARCHAR2(4) := 'JA';
    -- �󕥋敪
    cv_rcv_pay_div_plus       CONSTANT VARCHAR2(3) := '1';
    cv_rcv_pay_div_minus      CONSTANT VARCHAR2(3) := '-1';
    -- ����敪
    cv_dealings_div_hinsyu    CONSTANT VARCHAR2(3) := '308'; -- �i��U��
    cv_dealings_div_hinmoku   CONSTANT VARCHAR2(3) := '309'; -- �i�ڐU��
--
    -- *** ���[�J���E�ϐ� ***
-- 2008/10/24 v1.10 UPDATE START
    /*lv_from_xfer    VARCHAR2(32000) ; -- �ړ��ϑ�����
    lv_from_trni    VARCHAR2(32000) ; -- �ړ��ϑ��Ȃ�
    lv_from_prod_1  VARCHAR2(32000) ; -- ���Y�֘A�Freverse_id is null
    lv_from_adji_1  VARCHAR2(32000) ; -- �݌ɒ����F���L�ȊO�̃f�[�^�S��
    lv_from_adji_2  VARCHAR2(32000) ; -- �݌ɒ����F�d����ԕi
    lv_from_adji_3  VARCHAR2(32000) ; -- �݌ɒ����F�l�����
    lv_from_adji_4  VARCHAR2(32000) ; -- �݌ɒ����F�����݌�
    lv_from_adji_5  VARCHAR2(32000) ; -- �݌ɒ����F�ړ����ђ���
    lv_from_porc_1  VARCHAR2(32000) ; -- �w���֘A�F�����^�C�vRMA
    lv_from_porc_2  VARCHAR2(32000) ; -- �w���֘A�F�����^�C�vPO
    lv_from_omso    VARCHAR2(32000) ; -- �󒍊֘A
--
    -- UNION ALL����SQL�̋��ʕ�
    lv_select_inner VARCHAR2(32000) ;
    lv_where_inner  VARCHAR2(32000) ;
--
    lv_from         VARCHAR2(32000) ;
    lv_order_by     VARCHAR2(32000) ;
    lv_sql          VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k*/
    lv_select101_1    VARCHAR2(32000) ;
    lv_select101_2    VARCHAR2(32000) ;
    lv_select101_3    VARCHAR2(32000) ;
    lv_select101_4    VARCHAR2(32000) ;
    lv_select102_1    VARCHAR2(32000) ;
    lv_select102_2    VARCHAR2(32000) ;
    lv_select102_3    VARCHAR2(32000) ;
    lv_select102_4    VARCHAR2(32000) ;
    lv_select103_1    VARCHAR2(32000) ;
    lv_select103_2    VARCHAR2(32000) ;
    lv_select105_1    VARCHAR2(32000) ;
    lv_select105_2    VARCHAR2(32000) ;
    lv_select106_1    VARCHAR2(32000) ;
    lv_select106_2    VARCHAR2(32000) ;
    lv_select107_1    VARCHAR2(32000) ;
    lv_select107_2    VARCHAR2(32000) ;
    lv_select109_1    VARCHAR2(32000) ;
    lv_select109_2    VARCHAR2(32000) ;
    lv_select111_1    VARCHAR2(32000) ;
    lv_select111_2    VARCHAR2(32000) ;
    lv_select201_1    VARCHAR2(32000) ;
    lv_select201_2    VARCHAR2(32000) ;
    lv_select202_03_1 VARCHAR2(32000) ;
    lv_select202_03_2 VARCHAR2(32000) ;
    lv_select3xx_1    VARCHAR2(32000) ;
    lv_select31x_1    VARCHAR2(32000) ;
    lv_select4xx_1    VARCHAR2(32000) ;
    lv_select4xx_2    VARCHAR2(32000) ;
    lv_select4xx_3    VARCHAR2(32000) ;
    lv_select5xx_1    VARCHAR2(32000) ;
    lv_select5xx_2    VARCHAR2(32000) ;
    lv_select5xx_3    VARCHAR2(32000) ;
    lv_select504_09_1 VARCHAR2(32000) ;
    lv_select504_09_2 VARCHAR2(32000) ;
    lv_select504_09_3 VARCHAR2(32000) ;
--
    lv_where_category_crowd  VARCHAR2(32000) ;
    lv_where_in_crowd        VARCHAR2(32000) ;
    lv_order_by              VARCHAR2(32000) ;
--
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/24 v1.10 UPDATE END
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    get_data_cur101    ref_cursor;
    get_data_cur102    ref_cursor;
    get_data_cur103    ref_cursor;
    get_data_cur105    ref_cursor;
    get_data_cur106    ref_cursor;
    get_data_cur107    ref_cursor;
    get_data_cur109    ref_cursor;
    get_data_cur111    ref_cursor;
    get_data_cur201    ref_cursor;
    get_data_cur202_03 ref_cursor;
    get_data_cur3xx    ref_cursor;
    get_data_cur31x    ref_cursor;
    get_data_cur4xx    ref_cursor;
    get_data_cur5xx    ref_cursor;
    get_data_cur504_09 ref_cursor;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2008/10/24 v1.10 ADD START
    --===============================================================
    -- ��������.�󕥋敪       �� 101
    -- �Ώێ���敪(OMSO/PORC) �� 101:���ޏo��(�ΏۊO)
    --                            102:���i�o��
    --                            112:�U�֏o��_�o��
    --===============================================================
    lv_select101_1 :=
       -- '  SELECT /*+ leading ( itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm ) use_nl ( itp gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm ) */ '
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */ '
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '        OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id  = xoha.header_id'
    || '  AND    rsl.oe_order_line_id    = xola.line_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''102'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '        OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select101_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '     OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id  = xoha.header_id'
    || '  AND    rsl.oe_order_line_id    = xola.line_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    xola.request_item_code  <> xola.shipping_item_code'
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
--    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''112'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select101_3 :=
       '  SELECT /*+ leading (xoha xrpm ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha xrpm ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '        OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    ooha.header_id          = wdd.source_header_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xoha.header_id          = wdd.source_header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.line_id            = wdd.source_line_id'
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''102'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '       OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select101_4 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '       OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    xola.request_item_code  <> xola.shipping_item_code'
    || '  AND    ooha.header_id          = wdd.source_header_id'
    || '  AND    xoha.header_id          = ooha.header_id'
    || '  AND    xoha.header_id          = wdd.source_header_id'
    || '  AND    xola.order_header_id    = xoha.order_header_id'
    || '  AND    xola.line_id            = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
--    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''112'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''1'''
    || '  AND    xrpm.break_col_10         IS NOT NULL'
      ;
--
    --===============================================================
    -- ��������.�󕥋敪       �� 102
    -- �Ώێ���敪(OMSO/PORC) �� 105:�U�֗L��_�o��
    --                            108:���i�U�֗L��_�o��
    --===============================================================
    lv_select102_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''105'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select102_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''108'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select102_3 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''105'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select102_4 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''108'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪       �� 103
    -- �Ώێ���敪(OMSO/PORC) �� 105:�L��
    --===============================================================
    lv_select103_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.request_item_code    = xola.shipping_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = itp.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''103'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '         OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '  AND    xrpm.item_div_origin      IS NOT NULL'
    || '  AND    xrpm.item_div_ahead       IS NOT NULL'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select103_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '             iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '            ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '            ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '            ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '            ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '            ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '            ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '            ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '            ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '            ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '            ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '            ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '      FROM   ic_tran_pnd               itp'
    || '            ,wsh_delivery_details      wdd'
    || '            ,oe_order_headers_all      ooha'
    || '            ,oe_transaction_types_all  otta'
    || '            ,xxwsh_order_headers_all   xoha'
    || '            ,xxwsh_order_lines_all     xola'
    || '            ,ic_item_mst_b             iimb'
    || '            ,xxcmn_item_mst_b          ximb'
    || '            ,gmi_item_categories       gic1'
    || '            ,mtl_categories_b          mcb1'
    || '            ,gmi_item_categories       gic2'
    || '            ,mtl_categories_b          mcb2'
    || '            ,gmi_item_categories       gic3'
    || '            ,mtl_categories_b          mcb3'
    || '            ,xxcmn_stnd_unit_price_v   xsup'
    || '            ,xxcmn_rcv_pay_mst         xrpm'
    || '      WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '      AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '      AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '      AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '      AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '      AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '      AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '      AND    ooha.header_id            = wdd.source_header_id'
    || '      AND    otta.transaction_type_id  = ooha.order_type_id'
    || '      AND    ((otta.attribute4           <> ''2'')'
    || '             OR  (otta.attribute4       IS NULL))'
--    || '      AND    xoha.header_id            = ooha.header_id'
--    || '      AND    xola.line_id              = wdd.source_line_id'
    || '      AND    ooha.header_id            = wdd.source_header_id'
    || '      AND    xoha.header_id            = ooha.header_id'
    || '      AND    xoha.header_id            = wdd.source_header_id'
    || '      AND    xola.order_header_id      = xoha.order_header_id'
    || '      AND    xola.line_id              = wdd.source_line_id'
    || '      AND    xola.request_item_code    = xola.shipping_item_code'
    || '      AND    iimb.item_id              = itp.item_id'
    || '      AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '      AND    ximb.item_id              = itp.item_id'
    || '      AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '      AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '      AND    gic1.item_id              = itp.item_id'
    || '      AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '      AND    gic1.category_id          = mcb1.category_id'
    || '      AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '      AND    gic2.item_id              = itp.item_id'
    || '      AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '      AND    gic2.category_id          = mcb2.category_id'
    || '      AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '      AND    mcb2.segment1             = ''5'''
    || '      AND    gic3.item_id              = itp.item_id'
    || '      AND    gic3.category_id          = mcb3.category_id'
    || '      AND    xsup.item_id              = itp.item_id'
    || '      AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '      AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '      AND    xrpm.doc_type             = itp.doc_type'
    || '      AND    xrpm.doc_type             = ''OMSO'''
    || '      AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '      AND    xrpm.dealings_div         = ''103'''
    || '      AND    xoha.req_status           = ''08'''
    || '      AND    otta.attribute1           = ''2'''
--    || '      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '      AND    xrpm.shipment_provision_div = ''2'''
    || '      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)'
    || '             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))'
    || '      AND    xrpm.item_div_origin      IS NOT NULL'
    || '      AND    xrpm.item_div_ahead       IS NOT NULL'
    || '      AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪       �� 104(�ΏۊO)
    -- �Ώێ���敪(OMSO/PORC) �� 113:�U�֏o��_���o
    --===============================================================
--      CURSOR get_data_cur104 IS
--
    --===============================================================
    -- ��������.�󕥋敪       �� 105
    -- �Ώێ���敪(OMSO/PORC) �� 107:���i�U�֗L��_���
    --===============================================================
    lv_select105_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''107'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select105_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_ahead       = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic5.item_id              = itp.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_origin'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''107'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪       �� 106
    -- �Ώێ���敪(OMSO/PORC) �� 109:���i�U�֗L��_���o
    --===============================================================
    lv_select106_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola rsl itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb2.item_no             = xola.request_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_origin      = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = iimb2.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic5.item_id              = iimb2.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_ahead'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select106_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xrpm xola wdd itp gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,gmi_item_categories       gic5'
    || '        ,mtl_categories_b          mcb5'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb2.item_no             = xola.request_item_code'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    xrpm.prod_div_origin      = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
--    || '  AND    mcb2.segment1             = ''5'''
--    || '  AND    mcb2.segment1             = xrpm.item_div_origin'
    || '  AND    xrpm.item_div_origin      = ''5'''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = iimb2.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             = ''5'''
--    || '  AND    mcb4.segment1             = xrpm.item_div_ahead'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    || '  AND    gic5.item_id              = iimb2.item_id'
    || '  AND    gic5.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic5.category_id          = mcb5.category_id'
    || '  AND    mcb5.segment1             = xrpm.prod_div_ahead'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
--    || '  AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,''04'',''1'',''08'',''2'')'
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
-- 2008/12/02 v1.14 yoshida mod start
    --===============================================================
    -- ��������.�󕥋敪       �� 107
    -- �Ώێ���敪(OMSO/PORC) �� 104:�U�֗L��_���
    --===============================================================
    lv_select107_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''104'''
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
    lv_select107_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    mcb4.segment1             IN (''1'',''2'',''4'')'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''104'''
    || '  AND    xoha.req_status           = ''08'''
    || '  AND    otta.attribute1           = ''2'''
    || '  AND    xrpm.shipment_provision_div = ''2'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
-- 2008/12/02 v1.14 yoshida mod end
--
    --===============================================================
    -- ��������.�󕥋敪       �� 108(�ΏۊO)
    -- �Ώێ���敪(OMSO/PORC) �� 106:�U�֗L��_���o
    --===============================================================
--      CURSOR get_data_cur108 IS
--
-- 2008/12/02 v1.14 yoshida mod start
    --===============================================================
    -- ��������.�󕥋敪       �� 109
    -- �Ώێ���敪(OMSO/PORC) �� 110:�U�֏o��_���_��
    --===============================================================
    lv_select109_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
-- 2008/12/06 v1.16 miyata update start
--    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xrpm.dealings_div         = ''110'''
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/06 v1.16 miyata delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
    lv_select109_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
-- 2008/12/06 v1.16 miyata update start
--    || '  AND    xrpm.dealings_div         = ''109'''
    || '  AND    xrpm.dealings_div         = ''110'''
-- 2008/12/06 v1.16 miyata update end
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/06 v1.16 miyata delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/06 v1.16 miyata delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
    --===============================================================
    -- ��������.�󕥋敪       �� 111
    -- �Ώێ���敪(OMSO/PORC) �� 111:�U�֏o��_���_��
    --===============================================================
    lv_select111_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''PORC'''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''111'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/07 v1.17 yoshida delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/07 v1.17 yoshida delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
    lv_select111_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/07 v1.17 yoshida update start
    || '        ,CASE WHEN xrpm.dealings_div_name IN (''' || gv_d_name_trn_rcv || ''','
    || '                                              ''' || gv_d_name_item_trn_rcv || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_gen || ''','
    || '                                              ''' || gv_d_name_trn_ship_rcv_han || ''')'
    || '                   THEN itp.trans_qty * TO_NUMBER(''' || gc_rcv_pay_div_adj || ''')'
    || '              ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END                              trans_qty'
--    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
-- 2008/12/07 v1.17 yoshida update end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,gmi_item_categories       gic4'
    || '        ,mtl_categories_b          mcb4'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_no              = xola.request_item_code'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = iimb.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = iimb.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic4.item_id              = itp.item_id'
    || '  AND    gic4.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic4.category_id          = mcb4.category_id'
    || '  AND    xrpm.item_div_origin      = mcb4.segment1'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''OMSO'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         = ''111'''
    || '  AND    xoha.req_status           = ''04'''
    || '  AND    otta.attribute1           = ''1'''
    || '  AND    xrpm.shipment_provision_div = ''1'''
-- 2008/12/07 v1.17 yoshida delete start
--    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
-- 2008/12/07 v1.17 yoshida delete end
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    || '  AND    xrpm.shipment_provision_div = otta.attribute1'
    || '  AND    xrpm.item_div_ahead       = ''5'''
    ;
--
-- 2008/12/02 v1.14 yoshida mod end
    --===============================================================
    -- ��������.�󕥋敪          �� 201
    -- �Ώێ���敪(ADJI/PORC_PO) �� 202:�d��
    --===============================================================
    lv_select201_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itc.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty'  -- ����
    || '  FROM   ic_tran_cmp               itc'
--    || '        ,ic_adjs_jnl               iaj'
--    || '        ,ic_jrnl_mst               ijm'
--    || '        ,xxpo_rcv_and_rtn_txns     xrrt'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
--    || '  AND    iaj.trans_type          = itc.doc_type'
--    || '  AND    iaj.doc_id              = itc.doc_id'
--    || '  AND    iaj.doc_line            = itc.doc_line'
--    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_henpin || ''''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    ;
--
    lv_select201_2 :=
       '  SELECT /*+ leading ( itp gic1 mcb1 gic2 mcb2 rsl rt xrpm ) use_nl ( itp gic1 mcb1 gic2 mcb2 rsl rt xrpm ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,rcv_transactions          rt'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
    || '  AND    itp.trans_date            >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itp.trans_date            <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format|| '''))'
    || '  AND    rsl.shipment_header_id    = itp.doc_id'
    || '  AND    rsl.line_num              = itp.doc_line'
    || '  AND    rsl.source_document_code  = ''PO'''
    || '  AND    rt.shipment_line_id       = rsl.shipment_line_id'
    || '  AND    rt.transaction_id         = itp.line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id              = itp.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = itp.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = itp.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.source_document_code = rsl.source_document_code'
    || '  AND    xrpm.transaction_type     = rt.transaction_type'
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� 202
    --                            �� 203
    -- �Ώێ���敪(OMSO/PORC)    �� 201:�q��
    --                            �� 203:�ԕi
    --===============================================================
    lv_select202_03_1 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_porc || ''''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''201'',''203'')'
    || '  AND    otta.attribute1         = ''3'''
    || '  AND    xrpm.shipment_provision_div = ''3'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select202_03_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
    || '  AND    ((otta.attribute4           <> ''2'')'
    || '         OR  (otta.attribute4       IS NULL))'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_omso || ''''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''201'',''203'')'
    || '  AND    otta.attribute1           = ''3'''
    || '  AND    xrpm.shipment_provision_div = ''3'''
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� 301
    --                            �� 302
    --                            �� 303
    --                            �� 304
    --                            �� 305
    --                            �� 311
    --                            �� 312
    --                            �� 313
    --                            �� 314
    --                            �� 318
    --                            �� 319
    -- �Ώێ���敪(PROD)         �� 313:��̔����i
    --                            �� 314:�ԕi����
    --                            �� 301:����
    --                            �� 309:�i�ڐU��
    --                            �� 311:�
    --                            �� 307:�Z�b�g
    --===============================================================
    lv_select3xx_1 :=
       '  SELECT /*+ leading (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,gme_material_details      gmd'
    || '        ,gme_batch_header          gbh'
    || '        ,gmd_routings_b            grb'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_prod || ''''
    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
    || '  AND    itp.reverse_id          IS NULL'
    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    gmd.batch_id            = itp.doc_id'
    || '  AND    gmd.line_no             = itp.doc_line'
    || '  AND    gbh.batch_id            = gmd.batch_id'
    || '  AND    grb.routing_id          = gbh.routing_id'
    || '  AND    iimb.item_id            = itp.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id            = itp.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itp.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itp.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itp.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type           = itp.doc_type'
    || '  AND    xrpm.line_type          = itp.line_type'
    || '  AND    xrpm.dealings_div       <> ''' || cv_dealings_div_hinsyu || ''''
    || '  AND    xrpm.dealings_div       <> ''' || cv_dealings_div_hinmoku || ''''
    || '  AND    xrpm.routing_class      <> ''70'''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.line_type          = gmd.line_type'
    || '  AND    xrpm.routing_class      = grb.routing_class'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    || '  AND    ( ( ( gmd.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )'
    || '         OR ( xrpm.hit_in_div        = gmd.attribute5 ) )'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪          �� 313
    --                            �� 314
    -- �Ώێ���敪(PROD)         �� 309:
    --===============================================================
    lv_select31x_1 :=
       '  SELECT /*+ leading (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (itp gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,gme_material_details      gmd'
    || '        ,gme_batch_header          gbh'
    || '        ,gmd_routings_b            grb'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_prod || ''''
    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
    || '  AND    itp.reverse_id          IS NULL'
    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    gmd.batch_id            = itp.doc_id'
    || '  AND    gmd.line_no             = itp.doc_line'
    || '  AND    gbh.batch_id            = gmd.batch_id'
    || '  AND    grb.routing_id          = gbh.routing_id'
    || '  AND    iimb.item_id            = itp.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id            = itp.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itp.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itp.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itp.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type           = itp.doc_type'
    || '  AND    xrpm.line_type          = itp.line_type'
    || '  AND    xrpm.routing_class      = ''70'''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.line_type          = gmd.line_type'
    || '  AND    xrpm.routing_class      = grb.routing_class'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    || '  AND    ( ( ( gmd.attribute5 IS NULL ) AND ( xrpm.hit_in_div IS NULL ) )'
    || '         OR ( xrpm.hit_in_div        = gmd.attribute5 ) )'
    || '  AND    (EXISTS (SELECT 1'
    || '                  FROM   gme_material_details gmd2'
    || '                        ,gmi_item_categories  gic'
    || '                        ,mtl_categories_b     mcb'
    || '                  WHERE  gmd2.batch_id   = gmd.batch_id'
    || '                  AND    gmd2.line_no    = gmd.line_no'
    || '                  AND    gmd2.line_type  = -1'
    || '                  AND    gic.item_id     = gmd2.item_id'
    || '                  AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                  AND    gic.category_id = mcb.category_id'
    || '                  AND    mcb.segment1    = xrpm.item_div_origin))'
    || '  AND    (EXISTS (SELECT 1'
    || '                  FROM   gme_material_details gmd3'
    || '                        ,gmi_item_categories  gic'
    || '                        ,mtl_categories_b     mcb'
    || '                  WHERE  gmd3.batch_id   = gmd.batch_id'
    || '                  AND    gmd3.line_no    = gmd.line_no'
    || '                  AND    gmd3.line_type  = 1'
    || '                  AND    gic.item_id     = gmd3.item_id'
    || '                  AND    gic.category_set_id = ''' || cn_item_class_id || ''''
    || '                  AND    gic.category_id = mcb.category_id'
    || '                  AND    mcb.segment1    = xrpm.item_div_ahead))'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪             �� 401
    --                               �� 402
    -- �Ώێ���敪(ADJI/TRNI/XFER)  �� 401:�q�Ɉړ�_����
    --                               �� 402:�q�Ɉړ�_�o��
    --===============================================================
    lv_select4xx_1 :=
       '  SELECT /*+ leading (xmrh xmrl ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/11 v1.18 UPDATE START
--    || '        ,ABS(itc.trans_qty) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '        ,NVL(itc.trans_qty, 0)          trans_qty'  -- ����
-- 2008/12/11 v1.18 UPDATE END
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_adjs_jnl               iaj'
    || '        ,ic_jrnl_mst               ijm'
    || '        ,xxinv_mov_req_instr_lines xmrl'
    || '        ,xxinv_mov_req_instr_headers xmrh'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
--    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrh.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id'
    || '  AND    iaj.trans_type          = itc.doc_type'
    || '  AND    iaj.doc_id              = itc.doc_id'
    || '  AND    iaj.doc_line            = itc.doc_line'
    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)'
    || '  AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_idouteisei || ''''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/12/11 v1.18 UPDATE START
/*
    || '  AND    xrpm.rcv_pay_div       = CASE'
    || '                                    WHEN itc.trans_qty >= 0 THEN'
    || '                                      ''' || cv_rcv_pay_div_plus || ''''
    || '                                    WHEN itc.trans_qty <  0 THEN'
    || '                                      ''' || cv_rcv_pay_div_minus || ''''
    || '                                    ELSE xrpm.rcv_pay_div'
    || '                                  END'
*/
    || '  AND    xrpm.rcv_pay_div       = CASE'
    || '                                    WHEN itc.trans_qty >= 0 THEN'
    || '                                      ''' || cv_rcv_pay_div_minus || ''''
    || '                                    WHEN itc.trans_qty <  0 THEN'
    || '                                      ''' || cv_rcv_pay_div_plus || ''''
    || '                                    ELSE xrpm.rcv_pay_div'
    || '                                  END'

-- 2008/12/11 v1.18 UPDATE END
    ;
--
    lv_select4xx_2 :=
       '  SELECT /*+ leading (xmrih xmril ixm itp xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrih xmril ixm itp xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_pnd               itp'
    || '        ,ic_xfer_mst               ixm'
    || '        ,xxinv_mov_req_instr_lines xmril'
    || '        ,xxinv_mov_req_instr_headers xmrih'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type            = ''' || cv_doc_type_xfer || ''''
    || '  AND    itp.completed_ind       = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date          >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date          <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrih.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.mov_hdr_id         = xmril.mov_hdr_id'
    || '  AND    ixm.transfer_id         = itp.doc_id'
--    || '  AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)'
    || '  AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)'
    || '  AND    iimb.item_id            = itp.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    gic1.item_id            = itp.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itp.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itp.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itp.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type           = itp.doc_type'
    || '  AND    xrpm.reason_code        = itp.reason_code'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.rcv_pay_div        = CASE'
    || '                                     WHEN itp.trans_qty >= 0 THEN'
    || '                                          ''' || cv_rcv_pay_div_plus || ''''
    || '                                     ELSE ''' || cv_rcv_pay_div_minus || ''''
    || '                                   END'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    ;
--
    lv_select4xx_3 :=
       '  SELECT /*+ leading (xmrih xmril ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrih xmril ijm iaj itc xrpm gic1 mcb1 gic2 mcb2) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_adjs_jnl               iaj'
    || '        ,ic_jrnl_mst               ijm'
    || '        ,xxinv_mov_req_instr_lines xmril'
    || '        ,xxinv_mov_req_instr_headers xmrih'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = ''' || cv_doc_type_trni || ''''
    || '  AND    itc.reason_code         = ''' || gv_reason_code_trni || ''''
--    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.actual_arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xmrih.actual_arrival_date <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xmrih.mov_hdr_id         = xmril.mov_hdr_id'
    || '  AND    iaj.trans_type          = itc.doc_type'
    || '  AND    iaj.doc_id              = itc.doc_id'
    || '  AND    iaj.doc_line            = itc.doc_line'
    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)'
    || '  AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = itc.doc_type'
    || '  AND    xrpm.rcv_pay_div        = itc.line_type'
    || '  AND    xrpm.reason_code        = itc.reason_code'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.rcv_pay_div        = CASE'
    || '                                     WHEN itc.trans_qty >= 0 THEN'
    || '                                          ''' || cv_rcv_pay_div_plus || ''''
    || '                                     ELSE ''' || cv_rcv_pay_div_minus || ''''
    || '                                   END'
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    ;
--
    --===============================================================
    -- ��������.�󕥋敪             �� 501
    --                               �� 502
    --                               �� 504
    --                               �� 506
    --                               �� 508
    --                               �� 507
    --                               �� 509
    --                               �� 511
    --                               �� 503
    -- �Ώێ���敪(ADJI)            �� 501:�����݌�
    --                               �� 502:���̑�
    --                               �� 503:�o�����o
    --                               �� 505:�������o
    --                               �� 506:�I����
    --                               �� 507:�I����
    --                               �� 508:�]��
    --                               �� 510:�l��
    --                               �� 511:�َ��i�ڕ��o
    --                               �� 512:�َ��i�ڎ��
    --===============================================================
    lv_select5xx_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/14 v1.20 UPDATE START
--    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '        ,CASE WHEN xrpm.reason_code = ''X911'''
    || '              THEN itc.trans_qty'
    || '              ELSE itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || '         END  trans_qty'                                -- ����
-- 2008/12/14 v1.20 UPDATE END
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code       IN (''X911'''
    || '                                   ,''X912'''
    || '                                   ,''X921'''
    || '                                   ,''X922'''
    || '                                   ,''X931'''
    || '                                   ,''X932'''
    || '                                   ,''X941'''
    || '                                   ,''X952'''
    || '                                   ,''X953'''
    || '                                   ,''X954'''
    || '                                   ,''X955'''
    || '                                   ,''X956'''
    || '                                   ,''X957'''
    || '                                   ,''X958'''
    || '                                   ,''X959'''
    || '                                   ,''X960'''
    || '                                   ,''X961'''
    || '                                   ,''X962'''
    || '                                   ,''X963'''
-- 2008/11/19 v1.12 UPDATE START
--    || '                                   ,''X964'')'
    || '                                   ,''X964'''
    || '                                   ,''X965'''
    || '                                   ,''X966'')'
-- 2008/11/19 v1.12 UPDATE END
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    ;
--
    lv_select5xx_2 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_cmp               itc'
--    || '        ,ic_adjs_jnl               iaj'
--    || '        ,ic_jrnl_mst               ijm'
--    || '        ,xxpo_namaha_prod_txns     xnpt'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
--    || '  AND    iaj.trans_type          = itc.doc_type'
--    || '  AND    iaj.doc_id              = itc.doc_id'
--    || '  AND    iaj.doc_line            = itc.doc_line'
--    || '  AND    ijm.journal_id          = iaj.journal_id'
--    || '  AND    xnpt.entry_number       = TO_NUMBER(ijm.attribute1)'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        = ''' || cv_reason_code_hamaoka || ''''
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
    ;
--
    lv_select5xx_3 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'  -- ����
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        IN (''' || cv_reason_code_mokusi || ''',''' || cv_reason_code_sonota || ''',''' || cv_reason_code_mokusi_u || ''',''' || cv_reason_code_sonota_u || ''')'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/11/19 v1.12 DELETE START
--    || '  AND    xrpm.rcv_pay_div       = CASE'
--    || '                                    WHEN itc.trans_qty >= 0 THEN'
--    || '                                         ''' || cv_rcv_pay_div_plus || ''''
--    || '                                    ELSE ''' || cv_rcv_pay_div_minus || ''''
--    || '                                  END'
-- 2008/11/19 v1.12 DELETE END
    ;
--
    --===============================================================
    -- ��������.�󕥋敪             �� 505
    --                               �� 510
    -- �Ώێ���敪(ADJI/OMSO/PORC)  �� 504:���{
    --                               �� 509:�p�p
    --===============================================================
    lv_select504_09_1 :=
       '  SELECT /*+ leading ( xrpm itc gic1 mcb1 gic2 mcb2 ) use_nl ( xrpm itc gic1 mcb1 gic2 mcb2 ) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
    || '        ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty' -- ����
    || '  FROM   ic_tran_cmp               itc'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itc.doc_type            = xrpm.doc_type'
    || '  AND    itc.reason_code         = xrpm.reason_code'
    || '  AND    itc.trans_date         >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    itc.trans_date         <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    iimb.item_id            = itc.item_id'
    || '  AND    iimb.attribute15        = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id            = iimb.item_id'
    || '  AND    ximb.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    ximb.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    gic1.item_id            = itc.item_id'
    || '  AND    gic1.category_set_id    = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id        = mcb1.category_id'
    || '  AND    mcb1.segment1           = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id            = itc.item_id'
    || '  AND    gic2.category_set_id    = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id        = mcb2.category_id'
    || '  AND    mcb2.segment1           = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id            = itc.item_id'
    || '  AND    gic3.category_id        = mcb3.category_id'
    || '  AND    xsup.item_id            = itc.item_id'
    || '  AND    xsup.start_date_active <= TRUNC(itc.trans_date)'
    || '  AND    xsup.end_date_active   >= TRUNC(itc.trans_date)'
    || '  AND    xrpm.doc_type           = ''' || cv_doc_type_adji || ''''
    || '  AND    xrpm.reason_code        IN (''X931'''
    || '                                    ,''X932'')'
    || '  AND    xrpm.new_div_account    = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.break_col_10       IS NOT NULL'
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '  AND    xrpm.rcv_pay_div       = CASE'
--    || '                                    WHEN itc.trans_qty >= 0 THEN'
--    || '                                         ''' || cv_rcv_pay_div_plus || ''''
--    || '                                    ELSE ''' || cv_rcv_pay_div_minus || ''''
--    || '                                  END'
-- 2008/12/13 v1.19 T.Ohashi mod end
    ;
--
    lv_select504_09_2 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl itp) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '        ,itp.trans_qty            trans_qty'            -- ����
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'            -- ����
-- 2008/12/13 v1.19 T.Ohashi mod end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,rcv_shipment_lines        rsl'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_porc || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.doc_id                = rsl.shipment_header_id'
    || '  AND    itp.doc_line              = rsl.line_num'
--    || '  AND    ooha.header_id            = rsl.oe_order_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = rsl.oe_order_line_id'
    || '  AND    rsl.oe_order_header_id    = xoha.header_id'
    || '  AND    rsl.oe_order_line_id      = xola.line_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_porc || ''''
    || '  AND    xrpm.source_document_code = ''RMA'''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''504'',''509'')'
    || '  AND    xrpm.stock_adjustment_div = otta.attribute4'
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
--
    lv_select504_09_3 :=
       '  SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */'
    || '         iimb.item_no             item_code'            -- �i�ڃR�[�h
    || '        ,ximb.item_short_name     item_name'            -- �i�ږ���
    || '        ,xsup.stnd_unit_price     unit_price'           -- �����F�W������
    || '        ,xsup.stnd_unit_price_gen raw_material_cost'    -- �����F������
    || '        ,xsup.stnd_unit_price_sai agein_cost'           -- �����F�Đ���
    || '        ,xsup.stnd_unit_price_shi material_cost'        -- �����F���ޔ�
    || '        ,xsup.stnd_unit_price_hou pack_cost'            -- �����F���
    || '        ,xsup.stnd_unit_price_kei other_expense_cost'   -- �����F���̑��o��
    || '        ,mcb3.segment1                  crowd_code'     --�Q�R�[�h
    || '        ,SUBSTR(mcb3.segment1, 1, 3)    crowd_low'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 2)    crowd_mid'      --���Q
    || '        ,SUBSTR(mcb3.segment1, 1, 1)    crowd_high'     --��Q
-- 2008/12/13 v1.19 T.Ohashi mod start
--    || '        ,itp.trans_qty            trans_qty'            -- ����
    || '        ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty'            -- ����
-- 2008/12/13 v1.19 T.Ohashi mod end
    || '  FROM   ic_tran_pnd               itp'
    || '        ,wsh_delivery_details      wdd'
    || '        ,oe_order_headers_all      ooha'
    || '        ,oe_transaction_types_all  otta'
    || '        ,xxwsh_order_headers_all   xoha'
    || '        ,xxwsh_order_lines_all     xola'
    || '        ,ic_item_mst_b             iimb'
    || '        ,xxcmn_item_mst_b          ximb'
    || '        ,ic_item_mst_b             iimb2'
    || '        ,gmi_item_categories       gic1'
    || '        ,mtl_categories_b          mcb1'
    || '        ,gmi_item_categories       gic2'
    || '        ,mtl_categories_b          mcb2'
    || '        ,gmi_item_categories       gic3'
    || '        ,mtl_categories_b          mcb3'
    || '        ,xxcmn_stnd_unit_price_v   xsup'
    || '        ,xxcmn_rcv_pay_mst         xrpm'
    || '  WHERE  itp.doc_type              = ''' || cv_doc_type_omso || ''''
    || '  AND    itp.completed_ind         = ''' || cv_completed_ind || ''''
--    || '  AND    itp.trans_date           >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
--    || '  AND    itp.trans_date           <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    xoha.arrival_date        >= FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from || gc_first_date || ''',''' || gc_char_format || ''')'
    || '  AND    xoha.arrival_date        <= LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to || gc_first_date || ''',''' || gc_char_format || '''))'
    || '  AND    itp.line_detail_id        = wdd.delivery_detail_id'
--    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    otta.transaction_type_id  = ooha.order_type_id'
--    || '  AND    xoha.header_id            = ooha.header_id'
--    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    ooha.header_id            = wdd.source_header_id'
    || '  AND    xoha.header_id            = ooha.header_id'
    || '  AND    xoha.header_id            = wdd.source_header_id'
    || '  AND    xola.order_header_id      = xoha.order_header_id'
    || '  AND    xola.line_id              = wdd.source_line_id'
    || '  AND    iimb.item_id              = itp.item_id'
    || '  AND    iimb.attribute15          = ''' || cv_cost_manage_code || ''''
    || '  AND    ximb.item_id              = iimb.item_id'
    || '  AND    ximb.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    ximb.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    iimb2.item_no             = xola.shipping_item_code'
    || '  AND    gic1.item_id              = iimb2.item_id'
    || '  AND    gic1.category_set_id      = ''' || cn_prod_class_id || ''''
    || '  AND    gic1.category_id          = mcb1.category_id'
    || '  AND    mcb1.segment1             = ''' || ir_param.goods_class || ''''
    || '  AND    gic2.item_id              = iimb2.item_id'
    || '  AND    gic2.category_set_id      = ''' || cn_item_class_id || ''''
    || '  AND    gic2.category_id          = mcb2.category_id'
    || '  AND    mcb2.segment1             = ''' || ir_param.item_class || ''''
    || '  AND    gic3.item_id              = iimb2.item_id'
    || '  AND    gic3.category_id          = mcb3.category_id'
    || '  AND    xsup.item_id              = itp.item_id'
    || '  AND    xsup.start_date_active   <= TRUNC(itp.trans_date)'
    || '  AND    xsup.end_date_active     >= TRUNC(itp.trans_date)'
    || '  AND    xrpm.doc_type             = itp.doc_type'
    || '  AND    xrpm.doc_type             = ''' || cv_doc_type_omso || ''''
    || '  AND    xrpm.new_div_account      = ''' || ir_param.rcv_pay_div || ''''
    || '  AND    xrpm.dealings_div         IN (''504'',''509'')'
    || '  AND    xrpm.stock_adjustment_div = otta.attribute4'
    || '  AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11'
    || '  AND    xrpm.break_col_10         IS NOT NULL'
    ;
-- 2008/10/24 v1.10 ADD END
-- 2008/10/24 v1.10 DELETE START
    /*-- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
    -- INNER_SQL��SELECT��
    lv_select_inner := ' SELECT '
                    || ' ximv.item_no             item_code,          ' -- �i�ڃR�[�h
                    || ' ximv.item_short_name     item_name,          ' -- �i�ږ���
                    || ' xsup.stnd_unit_price     unit_price,         ' -- �����F�W������
                    || ' xsup.stnd_unit_price_gen raw_material_cost,  ' -- �����F������
                    || ' xsup.stnd_unit_price_sai agein_cost,         ' -- �����F�Đ���
                    || ' xsup.stnd_unit_price_shi material_cost,      ' -- �����F���ޔ�
                    || ' xsup.stnd_unit_price_hou pack_cost,          ' -- �����F���
                    || ' xsup.stnd_unit_price_kei other_expense_cost, ' -- �����F���̑��o��
                    ;
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
      lv_select_inner := lv_select_inner
                      || 'xicv.crowd_code                crowd_code, '        --�Q�R�[�h
                      || 'SUBSTR(xicv.crowd_code, 1, 3)  crowd_low,  '         --���Q
                      || 'SUBSTR(xicv.crowd_code, 1, 2)  crowd_mid,  '         --���Q
                      || 'SUBSTR(xicv.crowd_code, 1, 1)  crowd_high,  '         --��Q
                      ;
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
      lv_select_inner := lv_select_inner
                      || 'xicv.acnt_crowd_code                crowd_code, '    --�o���Q�R�[�h
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 3)  crowd_low,  '     --���Q
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 2)  crowd_mid,  '     --���Q
                      || 'SUBSTR(xicv.acnt_crowd_code, 1, 1)  crowd_high,  '     --��Q
                      ;
    END IF;
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    -- INNER_SQL��WHERE��
    lv_where_inner := ' AND it.trans_date '
                   || ' BETWEEN FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_from
                                                            || gc_first_date
                                                            || ''', '''
                                                            || gc_char_format
                                                            || ''')'
                   || ' AND LAST_DAY(FND_DATE.STRING_TO_DATE(''' || ir_param.exec_date_to
                                                                 || gc_first_date
                                                                 || ''', '''
                                                                 || gc_char_format
                                                                 || '''))'
                   || ' AND xlvv.lookup_type            = ''' || gc_lookup_type || ''' '
                   || ' AND xlvv.language               = ''' || cv_jpn || ''' '
                   || ' AND xlvv.source_lang            = ''' || cv_jpn || ''' '
                   || ' AND xlvv.attribute10            IS NOT NULL '
                   || ' AND (   (xlvv.start_date_active IS NULL) '
                   || '      OR (xlvv.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (xlvv.end_date_active   IS NULL) '
                   || '      OR (xlvv.end_date_active   >= TRUNC(it.trans_date))) '
                   || ' AND (   (ximv.start_date_active IS NULL) '
                   || '      OR (ximv.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (ximv.end_date_active   IS NULL) '
                   || '      OR (ximv.end_date_active   >= TRUNC(it.trans_date))) '
                   || ' AND ximv.cost_manage_code       = ''' || cv_cost_manage_code || ''' '
                   || ' AND ximv.item_id                = xicv.item_id '
                   || ' AND xicv.prod_class_code        = ''' || ir_param.goods_class || ''' '
                   || ' AND xicv.item_class_code        = ''' || ir_param.item_class || ''''
                   || ' AND (   (xsup.start_date_active IS NULL) '
                   || '      OR (xsup.start_date_active <= TRUNC(it.trans_date))) '
                   || ' AND (   (xsup.end_date_active   IS NULL) '
                   || '      OR (xsup.end_date_active   >= TRUNC(it.trans_date))) '
                   ;
--
    -- ----------------------------------------------------
    -- �p�����[�^�Œ��o���ς��where���ڂ̐���
    -- ----------------------------------------------------
    -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- �Q�R�[�h�����͂���Ă���ꍇ
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where_inner := lv_where_inner
                       || ' AND xicv.crowd_code = ''' || ir_param.crowd_code || ''''
                       ;
      END IF;
    END IF;
--
    -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
    IF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- �o���Q�R�[�h�����͂���Ă���ꍇ
       IF (ir_param.acct_crowd_code  IS NOT NULL) THEN
        lv_where_inner := lv_where_inner
                       || ' AND xicv.acnt_crowd_code = ''' || ir_param.acct_crowd_code || ''''
                       ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    -- 1:�ړ��ϑ�����
    lv_from_xfer := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- ����
                 || ' it.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                 -- from
                 || ' FROM '
                 || ' ic_tran_pnd               it,     '
                 || ' xxcmn_rcv_pay_mst_xfer_v  xrpmxv, '
                 || ' ic_xfer_mst               ixm,    ' -- �n�o�l�݌ɓ]���}�X�^
                 || ' xxinv_mov_req_instr_lines xmril,  ' -- �ړ��˗��^�w�����ׁi�A�h�I���j
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���VIEW2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                 || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������VIEW
                 || ' WHERE '
                 || '     it.doc_type             = ''' || cv_doc_type_xfer || ''' '
                 || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                 || ' AND it.doc_type             = xrpmxv.doc_type '
                 || ' AND it.reason_code          = xrpmxv.reason_code '
                 || ' AND xrpmxv.rcv_pay_div      = CASE '
                 || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                               || cv_rcv_pay_div_plus  || ''' '
                 || '                                 ELSE ''' || cv_rcv_pay_div_minus || ''' '
                 || '                               END '
                 || ' AND it.doc_id               = ixm.transfer_id '
                 || ' AND ixm.attribute1          = xmril.mov_line_id '
                 || ' AND xrpmxv.dealings_div     = xlvv.meaning '
                 || ' AND xrpmxv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND it.item_id              = ximv.item_id '
                 || ' AND it.item_id              = xsup.item_id '
                 || lv_where_inner
                 ;
    -- 2:�ړ��ϑ��Ȃ�
    lv_from_trni := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- ����
                 || ' it.trans_qty * TO_NUMBER(xrpmtv.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                 || ' FROM '
                 || ' ic_tran_cmp               it, '
                 || ' xxcmn_rcv_pay_mst_trni_v  xrpmtv, '
                 || ' ic_adjs_jnl               iaj, '    -- �n�o�l�݌ɒ����W���[�i��
                 || ' ic_jrnl_mst               ijm, '    -- �n�o�l�W���[�i���}�X�^
                 || ' xxinv_mov_req_instr_lines xmril, '  -- �ړ��˗��^�w�����ׁi�A�h�I���j
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                 || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                 || ' WHERE '
                 || ' it.doc_type                 = ''' || cv_doc_type_trni || ''' '
                 || ' AND it.doc_type             = xrpmtv.doc_type '
                 || ' AND it.line_type            = xrpmtv.rcv_pay_div '
                 || ' AND it.reason_code          = xrpmtv.reason_code '
                 || ' AND xrpmtv.rcv_pay_div      = CASE '
                 || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                               || cv_rcv_pay_div_plus  || ''' '
                 || '                                 ELSE ''' || cv_rcv_pay_div_minus || ''' '
                 || '                               END '
                 || ' AND it.doc_type             = iaj.trans_type '
                 || ' AND it.doc_id               = iaj.doc_id '
                 || ' AND it.doc_line             = iaj.doc_line '
                 || ' AND iaj.journal_id          = ijm.journal_id '
                 || ' AND ijm.attribute1          = xmril.mov_line_id '
                 || ' AND xrpmtv.dealings_div     = xlvv.meaning '
                 || ' AND xrpmtv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND it.item_id              = ximv.item_id '
                 || ' AND it.item_id              = xsup.item_id '
                 || lv_where_inner
                 ;
    -- 3:���Y�֘A�Freverse_id is null
    lv_from_prod_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmpv.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                 it, '
                   || ' xxcmn_rcv_pay_mst_prod_v    xrpmpv, '
                   || ' xxcmn_lookup_values2_v      xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v           ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v    xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v     xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_prod || ''' '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND it.reverse_id           IS NULL '
                   || ' AND it.doc_type             = xrpmpv.doc_type '
                   || ' AND it.line_type            = xrpmpv.line_type '
                   || ' AND it.doc_id               = xrpmpv.doc_id '
                   || ' AND it.doc_line             = xrpmpv.doc_line '
                   || ' AND xrpmpv.dealings_div     <> ''' || cv_dealings_div_hinsyu || ''' '
                   || ' AND xrpmpv.dealings_div     <> ''' || cv_dealings_div_hinmoku || ''' '
                   || ' AND xrpmpv.dealings_div     = xlvv.meaning '
                   || ' AND xrpmpv.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 4:�݌ɒ����F(�d����ԕi�A�l������A�����݌ɁA�ړ����ђ����A�َ��i�ڎ󕥁A���̑��󕥈ȊO)
    lv_from_adji_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it, '
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_henpin     || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_hamaoka    || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_aitezaiko  || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_idouteisei || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_mokusi     || ''' '
                   || ' AND it.reason_code          <> ''' || cv_reason_code_sonota     || ''' '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 5:�݌ɒ����F�d����ԕi
    lv_from_adji_2 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it, '         -- opm�����݌Ƀg����
                   || ' ic_adjs_jnl               iaj, '        -- opm�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst               ijm, '        -- opm�W���[�i���}�X�^
                   || ' xxpo_rcv_and_rtn_txns     xrrt, '       -- ����ԕi���уA�h�I��
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_henpin || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xrrt.txns_id            = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 6:�݌ɒ����F�l�����
    lv_from_adji_3 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   -- from
                   || ' FROM '
                   || ' ic_tran_cmp               it, '         -- opm�����݌Ƀg����
                   || ' ic_adjs_jnl               iaj, '        -- opm�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst               ijm, '        -- opm�W���[�i���}�X�^
                   || ' xxpo_namaha_prod_txns     xnpt, '       -- ���Z���уA�h�I��
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_hamaoka || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xnpt.entry_number       = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 7:�݌ɒ���(�َ��i�ڕ��o�A���̑����o)
    lv_from_adji_4 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it,     '
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   '
                   || ' xxcmn_item_mst2_v         ximv,   '
                   || ' xxcmn_item_categories6_v  xicv,   '
                   || ' xxcmn_stnd_unit_price_v   xsup    '
                   || ' WHERE '
                   || ' it.doc_type                = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type            = xrpmav.doc_type '
                   || ' AND (   it.reason_code     = ''' || cv_reason_code_mokusi || ''' '
                   || '      OR it.reason_code     = ''' || cv_reason_code_sonota || ''') '
                   || ' AND it.reason_code         = xrpmav.reason_code '
                   || ' AND xrpmav.rcv_pay_div     = CASE '
                   || '                                WHEN it.trans_qty >= 0 then '''
                                                                || cv_rcv_pay_div_plus  || ''' '
                   || '                                ELSE ''' || cv_rcv_pay_div_minus || ''' '
                   || '                              END '
                   || ' AND xrpmav.dealings_div    = xlvv.meaning '
                   || ' AND xrpmav.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id             = ximv.item_id '
                   || ' AND it.item_id             = xsup.item_id '
                   || lv_where_inner
                   ;
     -- 8:�݌ɒ����F�ړ����ђ���
    lv_from_adji_5 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                 || ' it.trans_qty trans_qty ' -- ����
                 || ' it.trans_qty * TO_NUMBER(xrpmav.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_cmp               it,     ' -- opm�����݌Ƀg����
                   || ' ic_adjs_jnl               iaj,    ' -- opm�݌ɒ����W���[�i��
                   || ' ic_jrnl_mst               ijm,    ' -- opm�W���[�i���}�X�^
                   || ' xxinv_mov_req_instr_lines xmrl,   ' -- �ړ��˗�/�x������
                   || ' xxcmn_rcv_pay_mst_adji_v  xrpmav, '
                   || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_adji || ''' '
                   || ' AND it.doc_type             = xrpmav.doc_type '
                   || ' AND it.reason_code          = ''' || cv_reason_code_idouteisei || ''' '
                   || ' AND iaj.trans_type          = it.doc_type '
                   || ' AND iaj.doc_id              = it.doc_id '
                   || ' AND iaj.doc_line            = it.doc_line '
                   || ' AND ijm.journal_id          = iaj.journal_id '
                   || ' AND xmrl.mov_line_id        = ijm.attribute1 '
                   || ' AND it.reason_code          = xrpmav.reason_code '
                   || ' AND xrpmav.rcv_pay_div      = CASE '
                   || '                                 WHEN it.trans_qty >= 0 THEN '''
                                                        || cv_rcv_pay_div_minus || ''' '
                   || '                                 WHEN it.trans_qty <  0 THEN '''
                                                        || cv_rcv_pay_div_plus || ''' '
                   || '                                 ELSE xrpmav.rcv_pay_div '
                   || '                               END '
                   || ' AND xrpmav.dealings_div     = xlvv.meaning '
                   || ' AND xrpmav.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 9:�w���֘A�F�����^�C�vRMA
    lv_from_porc_1 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START

                   || ' NVL2(xrpmprv.item_id, '
                   ||      ' it.trans_qty, '
                   ||      ' DECODE(xrpmprv.dealings_div_name,''' || gv_haiki || ''' '
                   ||      '       ,it.trans_qty '
                   ||      '       , ''' || gv_mihon || ''' '
                   ||      '       ,it.trans_qty '
                   ||      ',it.trans_qty * TO_NUMBER(xrpmprv.rcv_pay_div))) trans_qty ' -- ����

                   || ' DECODE(xrpmprv.dealings_div_name,''' || gv_haiki || ''' '
                   || '       ,it.trans_qty '
                   || '       , ''' || gv_mihon || ''' '
                   || '       ,it.trans_qty '
                   || ',it.trans_qty * TO_NUMBER(xrpmprv.rcv_pay_div)) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                    it,      '
                   || ' xxcmn_rcv_pay_mst_porc_rma10_v xrpmprv, '
                   || ' xxcmn_lookup_values2_v         xlvv,    ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v              ximv,    ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v       xicv,    ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v        xsup     ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_porc || ''' '
                   || ' AND it.doc_id               = xrpmprv.doc_id '
                   || ' AND it.doc_line             = xrpmprv.doc_line '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND xrpmprv.dealings_div    = xlvv.meaning '
                   || ' AND xrpmprv.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND ximv.item_id            = NVL(xrpmprv.item_id,it.item_id) '
                   || ' AND xsup.item_id            = NVL(xrpmprv.item_id,it.item_id) '
                   || lv_where_inner
                   ;
    -- 10:�w���֘A�F�����^�C�vPO
    lv_from_porc_2 := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START
--                   || ' it.trans_qty trans_qty ' -- ����
                   || ' it.trans_qty * TO_NUMBER(xrpmppv.rcv_pay_div) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                   || ' FROM '
                   || ' ic_tran_pnd                 it, '
                   || ' xxcmn_rcv_pay_mst_porc_po_v xrpmppv, '
                   || ' xxcmn_lookup_values2_v      xlvv,   ' -- �N�C�b�N�R�[�h���view2
                   || ' xxcmn_item_mst2_v           ximv,   ' -- �i�ڏ��r���[
                   || ' xxcmn_item_categories6_v    xicv,   ' -- �i�ڃJ�e�S���[�r���[
                   || ' xxcmn_stnd_unit_price_v     xsup    ' -- �W���������view
                   || ' WHERE '
                   || ' it.doc_type                 = ''' || cv_doc_type_porc || ''' '
                   || ' AND it.doc_id               = xrpmppv.doc_id '
                   || ' AND it.doc_line             = xrpmppv.doc_line '
                   || ' AND it.line_id              = xrpmppv.line_id '
                   || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                   || ' AND xrpmppv.dealings_div    = xlvv.meaning '
                   || ' AND xrpmppv.new_div_account = ''' || ir_param.rcv_pay_div || ''' '
                   || ' AND it.item_id              = ximv.item_id '
                   || ' AND it.item_id              = xsup.item_id '
                   || lv_where_inner
                   ;
    -- 11:�󒍊֘A
    lv_from_omso := lv_select_inner
-- 2008/08/28 v1.9 UPDATE START

                 || ' NVL2(xrpmov.item_id, '
                 ||      ' it.trans_qty, '
                 ||      ' DECODE(xrpmov.dealings_div_name,''' || gv_haiki || ''' '
                 ||      '       ,it.trans_qty '
                 ||      '       , ''' || gv_mihon || ''' '
                 ||      '       ,it.trans_qty '
                 ||      ',it.trans_qty * TO_NUMBER(xrpmov.rcv_pay_div))) trans_qty ' -- ����

                 || ' DECODE(xrpmov.dealings_div_name,''' || gv_haiki || ''' '
                 || '       ,it.trans_qty '
                 || '       , ''' || gv_mihon || ''' '
                 || '       ,it.trans_qty '
                 || ',it.trans_qty * TO_NUMBER(xrpmov.rcv_pay_div)) trans_qty ' -- ����
-- 2008/08/28 v1.9 UPDATE END
                 || ' FROM '
                 || ' ic_tran_pnd               it, '
                 || ' xxcmn_rcv_pay_mst_omso_v  xrpmov, '
                 || ' xxcmn_lookup_values2_v    xlvv,   ' -- �N�C�b�N�R�[�h���view2
                 || ' xxcmn_item_mst2_v         ximv,   ' -- �i�ڏ��r���[
                 || ' xxcmn_item_categories6_v  xicv,   ' -- �i�ڃJ�e�S���[�r���[
                 || ' xxcmn_stnd_unit_price_v   xsup    ' -- �W���������view
                 || ' WHERE '
                 || ' it.doc_type                 = ''' || cv_doc_type_omso || ''' '
                 || ' AND it.completed_ind        = ' || cv_completed_ind || ' '
                 || ' AND it.doc_type             = xrpmov.doc_type '
                 || ' AND it.line_detail_id       = xrpmov.doc_line '
                 || ' AND xrpmov.dealings_div     = xlvv.meaning '
                 || ' AND xrpmov.new_div_account  = ''' || ir_param.rcv_pay_div || ''' '
                 || ' AND xrpmov.arrival_date >= '
                 || '     FND_DATE.STRING_TO_DATE(''' || gv_exec_start || ''','''
                                                      || gc_char_dt_format || ''')' -- ���ד�
                 || ' AND xrpmov.arrival_date <= '
                 || '     FND_DATE.STRING_TO_DATE(''' || gv_exec_end || ''','''
                                                      || gc_char_dt_format || ''')' -- ���ד�
                 || ' AND ximv.item_id            = NVL(xrpmov.item_id,it.item_id) '
                 || ' AND xsup.item_id            = NVL(xrpmov.item_id,it.item_id) '
                 || lv_where_inner
                 ;
--
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
    lv_from := lv_from_xfer
            || ' UNION ALL '
            || lv_from_trni
            || ' UNION ALL '
            || lv_from_prod_1
            || ' UNION ALL '
            || lv_from_adji_1
            || ' UNION ALL '
            || lv_from_adji_2
            || ' UNION ALL '
            || lv_from_adji_3
            || ' UNION ALL '
            || lv_from_adji_4
            || ' UNION ALL '
            || lv_from_adji_5
            || ' UNION ALL '
            || lv_from_porc_1
            || ' UNION ALL '
            || lv_from_porc_2
            || ' UNION ALL '
            || lv_from_omso
            ;
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
    lv_order_by := ' ORDER BY'
                || ' crowd_code'      -- �Q�R�[�h
                || ',item_code'       -- �i�ڃR�[�h
                ;
--
    -- ====================================================
    -- �r�p�k����
    -- ====================================================
    lv_sql := lv_from || lv_order_by ;
--
    -- ====================================================
    -- �f�[�^���o
    -- ====================================================
    -- �I�[�v��
    OPEN lc_ref FOR lv_sql ;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref ;*/
-- 2008/10/24 v1.10 DELETE END
-- 2008/10/24 v1.10 ADD START
   -- �ǉ������̏�����
   lv_where_category_crowd := '';
   lv_where_in_crowd       := '';
--
   -- �ǉ������̐ݒ�
   -- �J�e�S���i�Q�ʁj
   IF (ir_param.crowd_kind = gc_crowd_kind) THEN
     lv_where_category_crowd := '  AND    gic3.category_set_id      = ''' || cn_crowd_code_id || '''';
--
     -- �Q�R�[�h
     IF (ir_param.crowd_code IS NOT NULL) THEN
       lv_where_in_crowd     := '  AND    mcb3.segment1          = ''' || ir_param.crowd_code || '''';
     END IF;
   -- �J�e�S���i�o���Q�ʁj
   ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
     lv_where_category_crowd := '  AND    gic3.category_set_id      = ''' || cn_acnt_crowd_code_id || '''';
--
     -- �o���Q�R�[�h
     IF (ir_param.acct_crowd_code IS NOT NULL) THEN
       lv_where_in_crowd     := '  AND    mcb3.segment1           = ''' || ir_param.acct_crowd_code || '''';
     END IF;
   END IF;
--
   -- �n�q�c�d�q  �a�x�吶��
   lv_order_by := ' ORDER BY'
                || ' crowd_code'      -- �Q�R�[�h
                || ',item_code'       -- �i�ڃR�[�h
                ;
--
    -- �Q��
    IF (ir_param.crowd_kind = gc_crowd_kind) THEN
      -- �Q�R�[�h������
      IF (ir_param.crowd_code  IS NULL) THEN
        --===============================================================
        -- ��������.�󕥋敪       �� 101
        -- �Ώێ���敪(OMSO/PORC) �� 101:���ޏo��(�ΏۊO)
        --                            102:���i�o��
        --                            112:�U�֏o��_�o��
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- �I�[�v��
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur101;
        --===============================================================
        -- ��������.�󕥋敪       �� 102
        -- �Ώێ���敪(OMSO/PORC) �� 105:�U�֗L��_�o��
        --                            108:���i�U�֗L��_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- �I�[�v��
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur102;
        --===============================================================
        -- ��������.�󕥋敪       �� 103
        -- �Ώێ���敪(OMSO/PORC) �� 105:�L��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- �I�[�v��
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur103;
        --===============================================================
        -- ��������.�󕥋敪       �� 104(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 113:�U�֏o��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur104;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur104;
        --===============================================================
        -- ��������.�󕥋敪       �� 105
        -- �Ώێ���敪(OMSO/PORC) �� 107:���i�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- �I�[�v��
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur105;
        --===============================================================
        -- ��������.�󕥋敪       �� 106
        -- �Ώێ���敪(OMSO/PORC) �� 109:���i�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- �I�[�v��
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur106;
        --===============================================================
        -- ��������.�󕥋敪       �� 107
        -- �Ώێ���敪(OMSO/PORC) �� 104:�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '107') THEN
          -- �I�[�v��
          OPEN  get_data_cur107 FOR lv_select107_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select107_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur107 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur107;
        --===============================================================
        -- ��������.�󕥋敪       �� 108(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 106:�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur108;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur108;
        --===============================================================
        -- ��������.�󕥋敪       �� 109
        -- �Ώێ���敪(OMSO/PORC) �� 110:�U�֏o��_���_��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '109') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'�󕥋敪�F109') ;
          -- �I�[�v��
          OPEN  get_data_cur109 FOR lv_select109_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select109_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur109 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur109;
        --===============================================================
        -- ��������.�󕥋敪       �� 111
        -- �Ώێ���敪(OMSO/PORC) �� 111:�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '111') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'�󕥋敪�F111') ;
          -- �I�[�v��
          OPEN  get_data_cur111 FOR lv_select111_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select111_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur111 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur111;
        --===============================================================
        -- ��������.�󕥋敪          �� 201
        -- �Ώێ���敪(ADJI/PORC_PO) �� 202:�d��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- �I�[�v��
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur201;
    --===============================================================
    -- ��������.�󕥋敪          �� 202
    --                            �� 203
    -- �Ώێ���敪(OMSO/PORC)    �� 201:�q��
    --                            �� 203:�ԕi
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- �I�[�v��
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur202_03;
        --===============================================================
        -- ��������.�󕥋敪          �� 301
        --                            �� 302
        --                            �� 303
        --                            �� 304
        --                            �� 305
        --                            �� 311
        --                            �� 312
        --                            �� 318
        --                            �� 319
        -- �Ώێ���敪(PROD)         �� 313:��̔����i
        --                            �� 314:�ԕi����
        --                            �� 301:����
        --                            �� 309:�i�ڐU��
        --                            �� 311:�
        --                            �� 307:�Z�b�g
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- �I�[�v��
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur3xx;
        --===============================================================
        -- ��������.�󕥋敪          �� 313
        --                            �� 314
        --                            �� 315
        --                            �� 316
        -- �Ώێ���敪(PROD)         �� 309:
        --                            �� 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
          -- �I�[�v��
          OPEN  get_data_cur31x FOR lv_select31x_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur31x;
        --===============================================================
        -- ��������.�󕥋敪             �� 401
        --                               �� 402
        -- �Ώێ���敪(ADJI/TRNI/XFER)  �� 401:�q�Ɉړ�_����
        --                               �� 402:�q�Ɉړ�_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- �I�[�v��
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur4xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 501
        --                               �� 502
        --                               �� 504
        --                               �� 506
        --                               �� 508
        --                               �� 507
        --                               �� 509
        --                               �� 511
        --                               �� 503
        -- �Ώێ���敪(ADJI)            �� 501:�����݌�
        --                               �� 502:���̑�
        --                               �� 503:�o�����o
        --                               �� 505:�������o
        --                               �� 506:�I����
        --                               �� 507:�I����
        --                               �� 508:�]��
        --                               �� 510:�l��
        --                               �� 511:�َ��i�ڕ��o
        --                               �� 512:�َ��i�ڎ��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- �I�[�v��
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur5xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 505
        --                               �� 510
        -- �Ώێ���敪(ADJI/OMSO/PORC)  �� 504:���{
        --                               �� 509:�p�p
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- �I�[�v��
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur504_09;
        END IF;
      ELSE
        --===============================================================
        -- ��������.�󕥋敪       �� 101
        -- �Ώێ���敪(OMSO/PORC) �� 101:���ޏo��(�ΏۊO)
        --                            102:���i�o��
        --                            112:�U�֏o��_�o��
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- �I�[�v��
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur101;
        --===============================================================
        -- ��������.�󕥋敪       �� 102
        -- �Ώێ���敪(OMSO/PORC) �� 105:�U�֗L��_�o��
        --                            108:���i�U�֗L��_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- �I�[�v��
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur102;
        --===============================================================
        -- ��������.�󕥋敪       �� 103
        -- �Ώێ���敪(OMSO/PORC) �� 105:�L��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- �I�[�v��
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur103;
        --===============================================================
        -- ��������.�󕥋敪       �� 104(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 113:�U�֏o��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur104;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur104;
        --===============================================================
        -- ��������.�󕥋敪       �� 105
        -- �Ώێ���敪(OMSO/PORC) �� 107:���i�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- �I�[�v��
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur105;
        --===============================================================
        -- ��������.�󕥋敪       �� 106
        -- �Ώێ���敪(OMSO/PORC) �� 109:���i�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- �I�[�v��
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur106;
        --===============================================================
        -- ��������.�󕥋敪       �� 107
        -- �Ώێ���敪(OMSO/PORC) �� 104:�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '107') THEN
          -- �I�[�v��
          OPEN  get_data_cur107 FOR lv_select107_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select107_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur107 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur107;
        --===============================================================
        -- ��������.�󕥋敪       �� 108(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 106:�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur108;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur108;
        --===============================================================
        -- ��������.�󕥋敪       �� 109
        -- �Ώێ���敪(OMSO/PORC) �� 110:�U�֏o��_���_��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '109') THEN
          -- �I�[�v��
          OPEN  get_data_cur109 FOR lv_select109_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select109_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur109 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur109;
        --===============================================================
        -- ��������.�󕥋敪       �� 111
        -- �Ώێ���敪(OMSO/PORC) �� 111:�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '111') THEN
          -- �I�[�v��
          OPEN  get_data_cur111 FOR lv_select111_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select111_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur111 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur111;
        --===============================================================
        -- ��������.�󕥋敪          �� 201
        -- �Ώێ���敪(ADJI/PORC_PO) �� 202:�d��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- �I�[�v��
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur201;
    --===============================================================
    -- ��������.�󕥋敪          �� 202
    --                            �� 203
    -- �Ώێ���敪(OMSO/PORC)    �� 201:�q��
    --                            �� 203:�ԕi
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- �I�[�v��
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur202_03;
        --===============================================================
        -- ��������.�󕥋敪          �� 301
        --                            �� 302
        --                            �� 303
        --                            �� 304
        --                            �� 305
        --                            �� 311
        --                            �� 312
        --                            �� 318
        --                            �� 319
        -- �Ώێ���敪(PROD)         �� 313:��̔����i
        --                            �� 314:�ԕi����
        --                            �� 301:����
        --                            �� 311:�
        --                            �� 307:�Z�b�g
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- �I�[�v��
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur3xx;
        --===============================================================
        -- ��������.�󕥋敪          �� 313
        --                            �� 314
        --                            �� 315
        --                            �� 316
        -- �Ώێ���敪(PROD)         �� 309:
        --                            �� 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
          -- �I�[�v��
          OPEN  get_data_cur31x FOR lv_select31x_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur31x;
        --===============================================================
        -- ��������.�󕥋敪             �� 401
        --                               �� 402
        -- �Ώێ���敪(ADJI/TRNI/XFER)  �� 401:�q�Ɉړ�_����
        --                               �� 402:�q�Ɉړ�_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- �I�[�v��
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur4xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 501
        --                               �� 502
        --                               �� 504
        --                               �� 506
        --                               �� 508
        --                               �� 507
        --                               �� 509
        --                               �� 511
        --                               �� 503
        -- �Ώێ���敪(ADJI)            �� 501:�����݌�
        --                               �� 502:���̑�
        --                               �� 503:�o�����o
        --                               �� 505:�������o
        --                               �� 506:�I����
        --                               �� 507:�I����
        --                               �� 508:�]��
        --                               �� 510:�l��
        --                               �� 511:�َ��i�ڕ��o
        --                               �� 512:�َ��i�ڎ��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- �I�[�v��
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur5xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 505
        --                               �� 510
        -- �Ώێ���敪(ADJI/OMSO/PORC)  �� 504:���{
        --                               �� 509:�p�p
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- �I�[�v��
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur504_09;
        END IF;
      END IF;
    -- �o���Q��
    ELSIF (ir_param.crowd_kind = gc_crowd_acct_kind) THEN
      -- �o���Q�R�[�h������
      IF (ir_param.acct_crowd_code  IS NULL) THEN
        --===============================================================
        -- ��������.�󕥋敪       �� 101
        -- �Ώێ���敪(OMSO/PORC) �� 101:���ޏo��(�ΏۊO)
        --                            102:���i�o��
        --                            112:�U�֏o��_�o��
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- �I�[�v��
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur101;
        --===============================================================
        -- ��������.�󕥋敪       �� 102
        -- �Ώێ���敪(OMSO/PORC) �� 105:�U�֗L��_�o��
        --                            108:���i�U�֗L��_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- �I�[�v��
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur102;
        --===============================================================
        -- ��������.�󕥋敪       �� 103
        -- �Ώێ���敪(OMSO/PORC) �� 105:�L��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- �I�[�v��
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur103;
        --===============================================================
        -- ��������.�󕥋敪       �� 104(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 113:�U�֏o��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur104;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur104;
        --===============================================================
        -- ��������.�󕥋敪       �� 105
        -- �Ώێ���敪(OMSO/PORC) �� 107:���i�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- �I�[�v��
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur105;
        --===============================================================
        -- ��������.�󕥋敪       �� 106
        -- �Ώێ���敪(OMSO/PORC) �� 109:���i�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- �I�[�v��
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur106;
        --===============================================================
        -- ��������.�󕥋敪       �� 108(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 106:�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur108;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur108;
        --===============================================================
        -- ��������.�󕥋敪          �� 201
        -- �Ώێ���敪(ADJI/PORC_PO) �� 202:�d��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- �I�[�v��
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur201;
    --===============================================================
    -- ��������.�󕥋敪          �� 202
    --                            �� 203
    -- �Ώێ���敪(OMSO/PORC)    �� 201:�q��
    --                            �� 203:�ԕi
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- �I�[�v��
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur202_03;
        --===============================================================
        -- ��������.�󕥋敪          �� 301
        --                            �� 302
        --                            �� 303
        --                            �� 304
        --                            �� 305
        --                            �� 311
        --                            �� 312
        --                            �� 318
        --                            �� 319
        -- �Ώێ���敪(PROD)         �� 313:��̔����i
        --                            �� 314:�ԕi����
        --                            �� 301:����
        --                            �� 311:�
        --                            �� 307:�Z�b�g
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- �I�[�v��
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur3xx;
        --===============================================================
        -- ��������.�󕥋敪          �� 313
        --                            �� 314
        --                            �� 315
        --                            �� 316
        -- �Ώێ���敪(PROD)         �� 309:
        --                            �� 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
          -- �I�[�v��
          OPEN  get_data_cur31x FOR lv_select31x_1
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur31x;
        --===============================================================
        -- ��������.�󕥋敪             �� 401
        --                               �� 402
        -- �Ώێ���敪(ADJI/TRNI/XFER)  �� 401:�q�Ɉړ�_����
        --                               �� 402:�q�Ɉړ�_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- �I�[�v��
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur4xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 501
        --                               �� 502
        --                               �� 504
        --                               �� 506
        --                               �� 508
        --                               �� 507
        --                               �� 509
        --                               �� 511
        --                               �� 503
        -- �Ώێ���敪(ADJI)            �� 501:�����݌�
        --                               �� 502:���̑�
        --                               �� 503:�o�����o
        --                               �� 505:�������o
        --                               �� 506:�I����
        --                               �� 507:�I����
        --                               �� 508:�]��
        --                               �� 510:�l��
        --                               �� 511:�َ��i�ڕ��o
        --                               �� 512:�َ��i�ڎ��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- �I�[�v��
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_2
                                 || lv_where_category_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur5xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 505
        --                               �� 510
        -- �Ώێ���敪(ADJI/OMSO/PORC)  �� 504:���{
        --                               �� 509:�p�p
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- �I�[�v��
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur504_09;
        END IF;
      ELSE
        --===============================================================
        -- ��������.�󕥋敪       �� 101
        -- �Ώێ���敪(OMSO/PORC) �� 101:���ޏo��(�ΏۊO)
        --                            102:���i�o��
        --                            112:�U�֏o��_�o��
        --===============================================================
        IF (ir_param.rcv_pay_div = '101') THEN
          -- �I�[�v��
          OPEN  get_data_cur101 FOR lv_select101_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select101_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur101 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur101;
        --===============================================================
        -- ��������.�󕥋敪       �� 102
        -- �Ώێ���敪(OMSO/PORC) �� 105:�U�֗L��_�o��
        --                            108:���i�U�֗L��_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '102') THEN
          -- �I�[�v��
          OPEN  get_data_cur102 FOR lv_select102_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select102_4
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur102 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur102;
        --===============================================================
        -- ��������.�󕥋敪       �� 103
        -- �Ώێ���敪(OMSO/PORC) �� 105:�L��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '103') THEN
          -- �I�[�v��
          OPEN  get_data_cur103 FOR lv_select103_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select103_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur103 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur103;
        --===============================================================
        -- ��������.�󕥋敪       �� 104(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 113:�U�֏o��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '104') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur104;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur104 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur104;
        --===============================================================
        -- ��������.�󕥋敪       �� 105
        -- �Ώێ���敪(OMSO/PORC) �� 107:���i�U�֗L��_���
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '105') THEN
          -- �I�[�v��
          OPEN  get_data_cur105 FOR lv_select105_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select105_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur105 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur105;
        --===============================================================
        -- ��������.�󕥋敪       �� 106
        -- �Ώێ���敪(OMSO/PORC) �� 109:���i�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '106') THEN
          -- �I�[�v��
          OPEN  get_data_cur106 FOR lv_select106_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select106_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur106 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur106;
        --===============================================================
        -- ��������.�󕥋敪       �� 108(�ΏۊO)
        -- �Ώێ���敪(OMSO/PORC) �� 106:�U�֗L��_���o
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '108') THEN
          NULL;
--          -- �I�[�v��
--          OPEN  get_data_cur108;
--          -- �o���N�t�F�b�`
--          FETCH get_data_cur108 BULK COLLECT INTO ot_data_rec;
--          -- �J�[�\���N���[�Y
--          CLOSE get_data_cur108;
        --===============================================================
        -- ��������.�󕥋敪          �� 201
        -- �Ώێ���敪(ADJI/PORC_PO) �� 202:�d��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div = '201') THEN
          -- �I�[�v��
          OPEN  get_data_cur201 FOR lv_select201_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select201_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur201 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur201;
    --===============================================================
    -- ��������.�󕥋敪          �� 202
    --                            �� 203
    -- �Ώێ���敪(OMSO/PORC)    �� 201:�q��
    --                            �� 203:�ԕi
    --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('202','203')) THEN
          -- �I�[�v��
          OPEN  get_data_cur202_03 FOR lv_select202_03_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select202_03_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur202_03 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur202_03;
        --===============================================================
        -- ��������.�󕥋敪          �� 301
        --                            �� 302
        --                            �� 303
        --                            �� 304
        --                            �� 305
        --                            �� 311
        --                            �� 312
        --                            �� 318
        --                            �� 319
        -- �Ώێ���敪(PROD)         �� 313:��̔����i
        --                            �� 314:�ԕi����
        --                            �� 301:����
        --                            �� 311:�
        --                            �� 307:�Z�b�g
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('301','302','303','304','305','311','312','318','319')) THEN
          -- �I�[�v��
          OPEN  get_data_cur3xx FOR lv_select3xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur3xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur3xx;
        --===============================================================
        -- ��������.�󕥋敪          �� 313
        --                            �� 314
        --                            �� 315
        --                            �� 316
        -- �Ώێ���敪(PROD)         �� 309:
        --                            �� 310:
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('313','314','315','316')) THEN
          -- �I�[�v��
          OPEN  get_data_cur31x FOR lv_select31x_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur31x BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur31x;
        --===============================================================
        -- ��������.�󕥋敪             �� 401
        --                               �� 402
        -- �Ώێ���敪(ADJI/TRNI/XFER)  �� 401:�q�Ɉړ�_����
        --                               �� 402:�q�Ɉړ�_�o��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('401','402')) THEN
          -- �I�[�v��
          OPEN  get_data_cur4xx FOR lv_select4xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select4xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur4xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur4xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 501
        --                               �� 502
        --                               �� 504
        --                               �� 506
        --                               �� 508
        --                               �� 507
        --                               �� 509
        --                               �� 511
        --                               �� 503
        -- �Ώێ���敪(ADJI)            �� 501:�����݌�
        --                               �� 502:���̑�
        --                               �� 503:�o�����o
        --                               �� 505:�������o
        --                               �� 506:�I����
        --                               �� 507:�I����
        --                               �� 508:�]��
        --                               �� 510:�l��
        --                               �� 511:�َ��i�ڕ��o
        --                               �� 512:�َ��i�ڎ��
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('501','502','503','504','506','507','508','509','511')) THEN
          -- �I�[�v��
          OPEN  get_data_cur5xx FOR lv_select5xx_1
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_2
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || ' UNION ALL '
                                 || lv_select5xx_3
                                 || lv_where_category_crowd
                                 || lv_where_in_crowd
                                 || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur5xx BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur5xx;
        --===============================================================
        -- ��������.�󕥋敪             �� 505
        --                               �� 510
        -- �Ώێ���敪(ADJI/OMSO/PORC)  �� 504:���{
        --                               �� 509:�p�p
        --===============================================================
        ELSIF (ir_param.rcv_pay_div IN ('505','510')) THEN
          -- �I�[�v��
          OPEN  get_data_cur504_09 FOR lv_select504_09_1
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_2
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || ' UNION ALL '
                                    || lv_select504_09_3
                                    || lv_where_category_crowd
                                    || lv_where_in_crowd
                                    || lv_order_by;
          -- �o���N�t�F�b�`
          FETCH get_data_cur504_09 BULK COLLECT INTO ot_data_rec;
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur504_09;
        END IF;
      END IF;
    END IF;
-- 2008/10/24 v1.10 ADD START
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
    -- ���ڔ���p
    lc_break_col            VARCHAR2(100) DEFAULT '-' ;            -- ���ڔ���؂�ւ�
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
    lv_rcv_pay_div          VARCHAR2(100) DEFAULT lc_break_init ;  -- �󕥋敪
    lv_col_idx              VARCHAR2(100) DEFAULT lc_break_init ;  -- ���ڈʒu
    lv_col_name             VARCHAR2(100) DEFAULT lc_break_init ;  -- ���ڃ^�O
--
    -- �l�擾�p�p
    ln_unit_price           xxcmn_lot_cost.unit_ploce%TYPE ;                   -- �P��
    ln_inv_qty              ic_tran_pnd.trans_qty%TYPE;                        -- �݌ɐ���
    ln_inv_amt              xxcmn_lot_cost.unit_ploce%TYPE;                    -- �݌ɋ��z
    ln_first_inv_qty        xxinv_stc_inventory_month_stck.monthly_stock%TYPE; -- �݌ɐ��ʁi����j
    ln_first_inv_amt        xxcmn_lot_cost.unit_ploce%TYPE;                    -- �݌ɋ��z�i����j
    ln_end_inv_qty          xxinv_stc_inventory_result.loose_amt%TYPE;         -- �݌ɐ��ʁi�����j
    ln_end_inv_amt          xxcmn_lot_cost.unit_ploce%TYPE;                    -- �݌ɋ��z�i�����j
--
    -- �v�Z�p
    ln_quantity             ic_tran_pnd.trans_qty%TYPE ;                       -- ����
    ln_qty_in               ic_tran_pnd.trans_qty%TYPE ;                       -- ���ʁi����j
    ln_qty_out              ic_tran_pnd.trans_qty%TYPE ;                       -- ���ʁi���o�j
    ln_amount               xxcmn_lot_cost.unit_ploce%TYPE ;                   -- ���z
    ln_amt_in               xxcmn_lot_cost.unit_ploce%TYPE ;                   -- ���z�i����j
    ln_amt_out              xxcmn_lot_cost.unit_ploce%TYPE ;                   -- ���z�i���o�j
    ln_position             NUMBER        DEFAULT 0 ;                          -- �|�W�V����
    ln_instr                NUMBER        DEFAULT 0 ;                          -- ���ڔ���ؑֈʒu
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
    ------------------
    -- xml�^�O�o�^����
    ------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       -- �^�O�^�C�v T:�^�O
                                                  --            D:�f�[�^
                                                  --            N:�f�[�^(NULL�̏ꍇ�^�O�������Ȃ�)
                                                  --            Z:�f�[�^(NULL�̏ꍇ0�\��)
       ,iv_name              IN        VARCHAR2                --   �^�O��
       ,iv_value             IN        VARCHAR2  DEFAULT NULL  --   �^�O�f�[�^(�ȗ���
       ,in_lengthb           IN        NUMBER    DEFAULT NULL  --   �������i�o�C�g�j(�ȗ���
       ,iv_index             IN        NUMBER    DEFAULT NULL  --   �C���f�b�N�X(�ȗ���
      )
    IS
      -- ----------------
      -- �Œ胍�[�J���萔
      -- ----------------
      cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_set_xml' ;   -- �v���O������
--
      -- --------------
      -- ���[�U�[�錾��
      -- --------------
      -- *** ���[�J���ϐ� ***
      ln_xml_idx NUMBER;
      ln_work    NUMBER;
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
      IF (iv_index IS NULL) THEN
        ln_xml_idx := gt_xml_data_table.COUNT + 1 ;
      ELSE
        ln_xml_idx := iv_index;
      END IF;
--
      --�^�O�Z�b�g
      gt_xml_data_table(ln_xml_idx).tag_name  := iv_name ; --<�^�O��>
      IF (ic_type = gc_t) THEN
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_t ;  --<�^�O�̂�>
      ELSE
        gt_xml_data_table(ln_xml_idx).tag_type  := gc_d ;  --<�^�O �� �f�[�^>
        IF (ic_type = gc_z) THEN
          gt_xml_data_table(ln_xml_idx).tag_value := NVL(iv_value, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(ln_xml_idx).tag_value := iv_value ;         --Null�ł����̂܂ܕ\��
        END IF;
      END IF;
--
      --�����؂�
      IF (in_lengthb IS NOT NULL) THEN
        gt_xml_data_table(ln_xml_idx).tag_value
          := SUBSTRB(gt_xml_data_table(ln_xml_idx).tag_value , gn_one , in_lengthb);
      END IF;
    END prc_set_xml;
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
    ln_quantity := 0;
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
--
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gv_report_id);
    -- ���{��
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- �S������
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- �S���Җ�
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
    -- �����N��(from)
    prc_set_xml('D', 'p_trans_ym_from',
                TO_CHAR(TO_DATE(ir_param.exec_date_from||gc_first_date, gc_char_format),
                        gc_char_ym_format));
    -- �����N��(to)
    prc_set_xml('D', 'p_trans_ym_to',
                TO_CHAR(TO_DATE(ir_param.exec_date_to||gc_first_date, gc_char_format),
                        gc_char_ym_format));
    -- ���i�敪
    prc_set_xml('D', 'p_item_div_code', ir_param.goods_class);
    prc_set_xml('D', 'p_item_div_name', gv_goods_class_name, 20);
    -- �󕥋敪
    prc_set_xml('D', 'p_rcv_pay_div_code', ir_param.rcv_pay_div);
    prc_set_xml('D', 'p_rcv_pay_div_name', gv_rcv_pay_div_name, 20);
    --
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- �󕥋敪�f�[�^�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('D', 'rcv_pay_div_code_sum', ir_param.rcv_pay_div);
    -- -----------------------------------------------------
    -- �Q�R�[�h(��)�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_crowd_l');
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
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
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_s');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_m');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_m');
          ------------------------------
          -- ��Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_l');
        END IF ;
--
        ------------------------------
        -- ��Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_l');
        -- -----------------------------------------------------
        -- ��Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ��Q�R�[�h
        prc_set_xml('D', 'crowd_code_large_sum', gt_main_data(i).crowd_high);
        ------------------------------
        -- ���Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd_m');
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
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
          ------------------------------
          -- ���Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd_s');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_m');
        END IF ;
--
        ------------------------------
        -- ���Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_m');
        -- -----------------------------------------------------
        -- ���Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���Q�R�[�h
        prc_set_xml('D', 'crowd_code_middle_sum', gt_main_data(i).crowd_mid);
        ------------------------------
        -- ���Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd_s');
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
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd');
          ------------------------------
          -- �Q�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_crowd');
          ------------------------------
          -- ���Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd_s');
        END IF ;
--
        ------------------------------
        -- ���Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd_s');
        -- -----------------------------------------------------
        -- ���Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���Q�R�[�h
        prc_set_xml('D', 'crowd_code_small_sum', gt_main_data(i).crowd_low);
        ------------------------------
        -- �Q�R�[�h�k�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'lg_crowd');
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
          ------------------------------
          -- �i�ڃR�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- �Q�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_crowd');
        END IF ;
--
        ------------------------------
        -- �Q�R�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T', 'g_crowd');
        -- -----------------------------------------------------
        -- �Q�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �Q�R�[�h
        prc_set_xml('D', 'crowd_code_sum', gt_main_data(i).crowd_code);
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
        lv_item_code  := NVL( gt_main_data(i).item_code, lc_break_null ) ;
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
      ln_quantity := ln_quantity + NVL(gt_main_data(i).trans_qty, 0);
--
      IF (   (gt_main_data.COUNT = i)
          OR (NVL(gt_main_data(i+1).item_code, lc_break_null) <> lv_item_code)) THEN
        ------------------------------
        -- �i�ڃR�[�h�f�J�n�^�O
        ------------------------------
        prc_set_xml('T','g_item');
        -- �i�ڃR�[�h
        prc_set_xml('D','item_code', gt_main_data(i).item_code);
        -- �i�ږ�
        prc_set_xml('D','item_name', gt_main_data(i).item_name);
        -- �������
        prc_set_xml('Z','quantity', ln_quantity);
-- 2008/11/29 v1.13 yoshida update start
        -- �W������
        /*prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price, gn_qty_dec));
        -- ������
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost,gn_qty_dec));
        -- �Đ���
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost, gn_qty_dec));
        -- ���ޔ�
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost, gn_qty_dec));
        -- ���
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost, gn_qty_dec));
        -- ���̑��o��
        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost,
                      gn_qty_dec));*/
-- 2008/12/03 v1.14 yoshida update start
        /*-- �W������
        prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price * ln_quantity, gn_qty_dec));
        -- ������
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost * ln_quantity,gn_qty_dec));
        -- �Đ���
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost * ln_quantity, gn_qty_dec));
        -- ���ޔ�
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost * ln_quantity, gn_qty_dec));
        -- ���
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost * ln_quantity, gn_qty_dec));
        -- ���̑��o��
        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost * ln_quantity,
                      gn_qty_dec));*/
        -- �W������
        prc_set_xml('Z','standard_cost', round(gt_main_data(i).unit_price * ln_quantity));
        -- ������
        prc_set_xml('Z','raw_material_cost',round(gt_main_data(i).raw_material_cost * ln_quantity));
        -- �Đ���
        prc_set_xml('Z','agein_cost', round(gt_main_data(i).agein_cost * ln_quantity));
        -- ���ޔ�
        prc_set_xml('Z','material_cost', round(gt_main_data(i).material_cost * ln_quantity));
        -- ���
        prc_set_xml('Z','pack_cost', round(gt_main_data(i).pack_cost * ln_quantity));
        -- ���̑��o��
-- 2008/12/06 v1.15 miyata update start
--        prc_set_xml('Z','other_expense_cost',round(gt_main_data(i).other_expense_cost * ln_quantity));
        prc_set_xml('Z','other_expense_cost', ( round(gt_main_data(i).unit_price * ln_quantity)
                                               - round(gt_main_data(i).raw_material_cost * ln_quantity)
                                               - round(gt_main_data(i).agein_cost * ln_quantity)
                                               - round(gt_main_data(i).material_cost * ln_quantity)
                                               - round(gt_main_data(i).pack_cost * ln_quantity)));
-- 2008/12/06 v1.15 miyata update end
-- 2008/12/03 v1.14 yoshida update end
-- 2008/11/29 v1.13 yoshida update end
        -- �i�ڃR�[�h�f�I���^�O
        prc_set_xml('T','/g_item');
--
        IF (gt_main_data.COUNT <> i) THEN
          lv_item_code := NVL( gt_main_data(i+1).item_code, lc_break_null );
        END IF;
--
        -- �W�v�l������
        ln_quantity           := 0;
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    ------------------------------
    -- �i�ڃR�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- �Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd');
    ------------------------------
    -- �Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd');
    ------------------------------
    -- ���Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_s');
    ------------------------------
    -- ���Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_s');
    ------------------------------
    -- ���Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_m');
    ------------------------------
    -- ���Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_m');
    ------------------------------
    -- ��Q�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_crowd_l');
    ------------------------------
    -- ��Q�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_crowd_l');
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
      iv_exec_date_from     IN     VARCHAR2         --   01 : �����N��(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : �����N��(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : �󕥋敪
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �W�v���
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
    lv_f_date               VARCHAR2(20);
    lv_e_date               VARCHAR2(20);
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
    gv_report_id                    := 'XXCMN770010T' ;      -- ���[ID
    gd_exec_date                    := SYSDATE ;             -- ���{��
    -- �p�����[�^�i�[
    --
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      iv_exec_date_from , gc_char_y_format),gc_char_y_format);
    IF (lv_f_date IS NULL) THEN
      lr_param_rec.exec_date_from := iv_exec_date_from;
    ELSE
      lr_param_rec.exec_date_from := lv_f_date;
    END IF;                                                  -- �����N��FROM
--
    lv_e_date := TO_CHAR(FND_DATE.STRING_TO_DATE(
                      iv_exec_date_to , gc_char_y_format),gc_char_y_format);
    IF (lv_e_date IS NULL) THEN
      lr_param_rec.exec_date_to := iv_exec_date_to;
    ELSE
      lr_param_rec.exec_date_to := lv_e_date;
    END IF;                                                  -- �����N��TO
--
    lr_param_rec.goods_class        := iv_goods_class ;      -- ���i�敪
    lr_param_rec.item_class         := iv_item_class ;       -- ���i�敪
    lr_param_rec.rcv_pay_div        := iv_rcv_pay_div;       -- �󕥋敪
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                   <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_crowd_dtl>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_crowd_low>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_crowd_mid>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_crowd_high>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_crowd_high>' ) ;
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
     ,iv_exec_date_from     IN     VARCHAR2         --   01 : �����N��(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : �����N��(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : �󕥋敪
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �W�v���
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
        iv_exec_date_from     =>     iv_exec_date_from      --   01 : �����N��(from)
       ,iv_exec_date_to       =>     iv_exec_date_to        --   02 : �����N��(to)
       ,iv_goods_class        =>     iv_goods_class         --   03 : ���i�敪
       ,iv_item_class         =>     iv_item_class          --   04 : �i�ڋ敪
       ,iv_rcv_pay_div        =>     iv_rcv_pay_div         --   05 : �󕥋敪
       ,iv_crowd_kind         =>     iv_crowd_kind          --   06 : �W�v���
       ,iv_crowd_code         =>     iv_crowd_code          --   07 : �Q�R�[�h
       ,iv_acct_crowd_code    =>     iv_acct_crowd_code     --   08 : �o���Q�R�[�h
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
END XXCMN770010C ;
/
