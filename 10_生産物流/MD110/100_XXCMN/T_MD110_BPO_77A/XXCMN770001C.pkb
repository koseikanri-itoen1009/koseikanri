CREATE OR REPLACE PACKAGE BODY xxcmn770001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770001c(body)
 * Description      : �󕥎c���\�i�T�j�����E���ށE�����i
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77A)
 * Version          : 1.3
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(A-1)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(A-2)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/02    1.0   M.Inamine        �V�K�쐬
 *  2008/05/16    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[�ɂȂ�
 *                                       �_���C���B
 *                                       ���[��ʖ��́A�i�ڋ敪���́A���i�敪���́A�Q��ʖ��̂�
 *                                       �ő咷������ǉ��B
 *                                       �S�������A�S���Җ��̍ő咷������ύX�B
 *                                       (SUBSTR �� SUBSTRB)
 *  2008/05/30    1.2   R.Tomoyose       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal           CONSTANT VARCHAR2(1)  := '0';
  gv_status_warn             CONSTANT VARCHAR2(1)  := '1';
  gv_status_error            CONSTANT VARCHAR2(1)  := '2';
  gv_msg_part                CONSTANT VARCHAR2(3)  := ' : ';
  gv_msg_cont                CONSTANT VARCHAR2(3)  := '.';
  gv_hifn                    CONSTANT VARCHAR2(1)  := '-';
  gv_ja                      CONSTANT VARCHAR2(2)  := 'JA';
  gv_qty_prf                 CONSTANT VARCHAR2(4)  := '_qty';
  gv_amt_prf                 CONSTANT VARCHAR2(4)  := '_amt';
  gn_po_qty                  CONSTANT NUMBER       := 1;
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
  gv_pkg_name                CONSTANT VARCHAR2(20) := 'xxcmn770001C';   -- �p�b�P�[�W��
  gv_print_name              CONSTANT VARCHAR2(50) :='�󕥎c���\�i�T�j�����E���ށE�����i';--���[��
--
  ------------------------------
  -- �����^�C�v
  ------------------------------
  gv_doc_type_xfer           CONSTANT VARCHAR2(5)  := 'XFER';  --
  gv_doc_type_trni           CONSTANT VARCHAR2(5)  := 'TRNI';  --
  gv_doc_type_adji           CONSTANT VARCHAR2(5)  := 'ADJI';  --
  gv_doc_type_prod           CONSTANT VARCHAR2(5)  := 'PROD';  --
  gv_doc_type_porc           CONSTANT VARCHAR2(5)  := 'PORC';  --
  gv_doc_type_omso           CONSTANT VARCHAR2(5)  := 'OMSO';  --
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
  -- ���b�N�A�b�v�@�^�C�v
  ------------------------------
  gc_lookup_type_print_class CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_TYPE';-- ���[���
  gc_lookup_type_print_flg   CONSTANT VARCHAR2(50) := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';-- �����
  gc_lookup_type_crowd_kind  CONSTANT VARCHAR2(50) := 'XXCMN_MC_OUPUT_DIV';           -- �Q���
  gc_lookup_type_dealing_div CONSTANT VARCHAR2(50) := 'XXCMN_DEALINGS_DIV' ;          -- ����敪
--
  ------------------------------
  -- �o�͍��ڂ̗�ʒu�ő�l
  ------------------------------
  gc_print_pos_max           CONSTANT NUMBER := 19;--���ڏo�͈ʒu�Ō�
  gc_pay_pos_strt            CONSTANT NUMBER := 08;--���o�擪���ڈʒu
  ------------------------------
  -- �����N���̌��ʒu
  ------------------------------
  gc_exec_year_y             CONSTANT NUMBER := 05;--
  gc_exec_year_m             CONSTANT NUMBER := 04;--
  gc_m_pos                   CONSTANT NUMBER := 02;--
  ------------------------------
  -- ���[���
  ------------------------------
  gc_print_type1             CONSTANT VARCHAR2(1) := '1';--�q�ɕʁE�i�ڕ�
  gc_print_type2             CONSTANT VARCHAR2(1) := '2';--�i�ڕ�
   ------------------------------
  -- �Q���
  ------------------------------
  gc_grp_type3               CONSTANT VARCHAR2(1) := '3';--�Q��
  gc_grp_type4               CONSTANT VARCHAR2(1) := '4';--�o���Q��
  ------------------------------
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class     CONSTANT VARCHAR2(10) := '���i�敪';
  gc_cat_set_item_class      CONSTANT VARCHAR2(10) := '�i�ڋ敪';
  ------------------------------
  -- �����敪
  ------------------------------
  gc_cost_ac                 CONSTANT VARCHAR2(1) := '0';--���ی���
  gc_cost_st                 CONSTANT VARCHAR2(1) := '1';--�W������
  gc_price_sel               CONSTANT NUMBER      :=  7; --�����ʏW�v�J�E���^
  ------------------------------
  -- ���b�g�Ǘ�
  ------------------------------
  gc_lot_ctl_n               CONSTANT VARCHAR2(1) := '0';--�ΏۊO
  gc_lot_ctl_y               CONSTANT VARCHAR2(1) := '1';--�Ώ�
--
  ------------------------------
  -- �󕥋敪
  ------------------------------
  gc_rcv_pay_div_in          CONSTANT VARCHAR2(1) :=  '1' ;  --���
  gc_rcv_pay_div_out         CONSTANT VARCHAR2(2) := '-1' ;  --���o
  ------------------------------
  -- ����敪
  ------------------------------
  gv_dealings_div_prod1      CONSTANT VARCHAR2(10)  := '�i��U��';
  gv_dealings_div_prod2      CONSTANT VARCHAR2(10)  := '�i�ڐU��';
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application             CONSTANT VARCHAR2(5)  := 'XXCMN';-- �A�v���P�[�V����
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_ym_format          CONSTANT VARCHAR2(30) := 'YYYYMM';
  gc_char_d_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  gc_char_dt_format          CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  gc_e_time                  CONSTANT VARCHAR2(10) := ' 23:59:59';
  gv_month_edt               CONSTANT VARCHAR2(07) := 'MONTH';--�����N���̑O���v�Z�p
  gv_fdy                     CONSTANT VARCHAR2(02) :=  '01';  --�������t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(6)                          -- 01 : �����N��    �i�K�{)
     ,goods_class         xxcmn_lot_each_item_v.prod_div%TYPE-- 02 : ���i�敪    �i�K�{)
     ,item_class          xxcmn_lot_each_item_v.item_div%TYPE-- 03 : �i�ڋ敪    �i�K�{)
     ,print_kind          VARCHAR2(10)                         -- 04 : ���[���    �i�K�{)
     ,locat_code          VARCHAR2(10)                         -- 05 : �q�ɃR�[�h  �i�C��)
     ,crowd_kind          VARCHAR2(10)                         -- 06 : �Q���      �i�K�{)
     ,crowd_code          VARCHAR2(10)                         -- 07 : �Q�R�[�h    �i�C��)
     ,acnt_crowd_code     VARCHAR2(10)                         -- 08 : �o���Q�R�[�h�i�C��)
    );
--
  -- �i�ږ��׏W�v���R�[�h
  TYPE qty_array IS VARRAY(23) OF NUMBER;
  qty qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  TYPE amt_array IS VARRAY(23) OF NUMBER;
  amt qty_array := qty_array(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
--
  -- ����敪���̃^�O���̔z��ݒ�
  TYPE tag_name_array IS VARRAY(19) OF VARCHAR2(20);
  tag_name tag_name_array := tag_name_array(
     'po'                        -- 1 �d��
    ,'remanfct'                  -- 2 �Đ�
    ,'bld'                       -- 3 ���g
    ,'remanfct_bld'              -- 4 �Đ����g
    ,'prdct'                     -- 5 ���i���
    ,'mat_semiprdct'             -- 6 �����E�����i���
    ,'others'                    -- 7 ���̑�
    ,'exp_remanfct'              -- 8 �Đ�
    ,'exp_bld'                   -- 9 �u�����h���g
    ,'exp_remanfct_bld'          --10 �Đ����g
    ,'pak'                       --11 �
    ,'set'                       --12 �Z�b�g
    ,'okinawa'                   --13 ����
    ,'ons'                       --14 �L��
    ,'bas'                       --15 ���_
    ,'out_trnsfr'                --16 �U�֏o��
    ,'out_pdrct'                 --17 ���i��
    ,'out_mat_semiprdct'         --18 �����E�����i��
    ,'out_other');               --19 ���̑�
--
  -- �󕥎c���\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
     whse_code              ic_whse_mst.whse_code                    %TYPE-- �q�ɃR�[�h
    ,whse_name              ic_whse_mst.whse_name                    %TYPE-- �q�ɖ���
    ,trns_id                ic_tran_pnd.trans_id                     %TYPE-- TRANS_ID
    ,cost_mng_clss          xxcmn_lot_each_item_v.item_attribute15   %TYPE-- �����敪
    ,lot_ctl                xxcmn_lot_each_item_v.lot_ctl            %TYPE-- ���b�g�Ǘ�
    ,actual_unit_price      xxcmn_lot_each_item_v.actual_unit_price  %TYPE-- ���ےP��
    ,print_pos              xxcmn_lookup_values2_v.attribute1        %TYPE-- �󎚈ʒu
    ,reason_code            ic_tran_pnd.reason_code                  %TYPE-- ���R�R�[�h
    ,trans_date             ic_tran_pnd.trans_date                   %TYPE-- �����
    ,trans_ym               VARCHAR2(06) -- ����N��
    ,rcv_pay_div            xxcmn_rcv_pay_mst_xfer_v.rcv_pay_div     %TYPE-- �󕥋敪
    ,dealings_div           xxcmn_rcv_pay_mst_xfer_v.dealings_div    %TYPE-- ����敪
    ,doc_type               xxcmn_rcv_pay_mst_xfer_v.doc_type        %TYPE-- �����^�C�v
    ,item_div               xxcmn_lot_each_item_v.item_div           %TYPE-- �i�ڋ敪
    ,prod_div               xxcmn_lot_each_item_v.prod_div           %TYPE-- ���i�敪
    ,crowd_code             xxcmn_lot_each_item_v.crowd_code         %TYPE-- �Q�R�[�h
    ,crowd_low              VARCHAR2(05)--���Q
    ,crowd_mid              VARCHAR2(05)--���Q
    ,crowd_high             VARCHAR2(05)--��Q
    ,item_id                xxcmn_lot_each_item_v.item_id            %TYPE-- �i�ڂh�c
    ,lot_id                 xxcmn_lot_each_item_v.lot_id             %TYPE-- ���b�g�h�c
    ,trans_qty              ic_tran_pnd.trans_qty                    %TYPE-- �������
    ,arrival_date           ic_tran_pnd.trans_date                   %TYPE-- ���ד�
    ,arrival_ym             VARCHAR2(06)                                  -- ���הN��
    ,item_code              xxcmn_lot_each_item_v.item_code          %TYPE-- �i�ڃR�[�h
    ,item_name              xxcmn_lot_each_item_v.item_short_name    %TYPE-- �i�ڗ���
    ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
-- ���[���
  gv_user_dept              xxcmn_locations_all.location_short_name  %TYPE;-- �S������
  gv_user_name              per_all_people_f.per_information18       %TYPE;-- �S����
  gv_goods_class_name       mtl_categories_tl.description            %TYPE;-- ���i�敪��
  gv_item_class_name        mtl_categories_tl.description            %TYPE;-- �i�ڋ敪��
  gv_crowd_kind_name        mtl_categories_tl.description            %TYPE;-- �Q��ʖ�
  gv_print_class_name       mtl_categories_tl.description            %TYPE;-- ���[��ʖ���
--
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id              VARCHAR2(12);    -- ���[ID
  gd_exec_date              DATE        ;    -- ���{��
--
  gt_body_data              tab_data_type_dtl;       -- �擾���R�[�h�\
  gt_xml_data_table         XML_DATA;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER DEFAULT 0;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
  ------------------------------
  -- �W�v����
  ------------------------------
  gd_s_date               DATE;          -- �J�n��
  gd_e_date               DATE;          -- �I����
  gd_follow_date          DATE;          -- �����N��
  gd_prv1_last_date       DATE;          -- �O���̖���
  gd_prv2_last_date       DATE;          -- �O�X���̖���
  gd_flw_dt_chr           VARCHAR2(20);  -- �����N������
  gd_prv1_dt_chr          VARCHAR2(20);  -- �O���̖�������
  gd_prv2_dt_chr          VARCHAR2(20);  -- �O�X���̖�������
  ------------------------------
  --  �O���W�v�p
  ------------------------------
  gn_fst_inv_qty          NUMBER DEFAULT 0;--����
  gn_fst_inv_amt          NUMBER DEFAULT 0;--���z
  ------------------------------
  --  �I���W�v�p
  ------------------------------
  gn_lst_inv_qty          NUMBER DEFAULT 0;--����
  gn_lst_inv_amt          NUMBER DEFAULT 0;--���z
  ------------------------------
  --  ���[�����v�J�E���^
  ------------------------------
  ln_position             NUMBER DEFAULT 0;-- �|�W�V����
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt     EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt         EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt  EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  �Œ蕔 END   ############################
--
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
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml';   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'>'||iv_value||'</'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF;
--
    RETURN(lv_convert_data);
--
  END fnc_conv_xml;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(A-1)
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_initialize'; -- �v���O������
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
    -- �G���[�R�[�h
    lc_err_code        CONSTANT VARCHAR2(30) := 'APP-XXCMN-10010';
    -- �g�[�N����
    lc_token_name_01   CONSTANT VARCHAR2(30) := 'PARAMETER';
    lc_token_name_02   CONSTANT VARCHAR2(30) := 'VALUE';
    -- �g�[�N���l
    lc_token_value     CONSTANT VARCHAR2(30) := '�����N��';
--
    -- *** ���[�J���ϐ� ***
    ld_param_date DATE;
--
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION;     -- �l�擾�G���[
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
    gv_user_dept := SUBSTRB(gv_user_dept, 1, 10);
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id );
    gv_user_name := SUBSTRB(gv_user_name, 1, 14);
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
    ld_param_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month , gc_char_ym_format) ;
    IF ( ld_param_date IS NULL ) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_retcode := gv_status_error ;
      lv_errbuf  := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                             ,iv_name          => lc_err_code
                                             ,iv_token_name1   => lc_token_name_01
                                             ,iv_token_value1  => lc_token_value
                                             ,iv_token_name2   => lc_token_name_02
                                             ,iv_token_value2  => ir_param.exec_year_month ) ;
      RAISE get_value_expt ;
    END IF ;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
      ov_retcode := lv_retcode;
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
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(A-2)
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�ϐ� ***
    lv_f_date     VARCHAR2(100);
    lv_select1    VARCHAR2(5000) ;
    lv_select2    VARCHAR2(5000) ;
    lv_from       VARCHAR2(5000) ;
    lv_where      VARCHAR2(5000) ;
    lv_order_by   VARCHAR2(5000) ;
    lv_sql        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql2       VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql3       VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
--
    lv_sql_xfer      VARCHAR2(5000);
    lv_sql_trni      VARCHAR2(5000);
    lv_sql_adji      VARCHAR2(5000);
    lv_sql_adji_po   VARCHAR2(5000);
    lv_sql_adji_hm   VARCHAR2(5000);
    lv_sql_adji_mv   VARCHAR2(5000);
    lv_sql_adji_snt  VARCHAR2(5000);
    lv_sql_prod      VARCHAR2(5000);
    lv_sql_prod_i    VARCHAR2(5000);
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
    --prod�iReverse_id�Ȃ��j�i��E�i�ڐU��
    lv_select_prod_i     VARCHAR2(5000);
    lv_from_prod_i       VARCHAR2(5000);
    lv_where_prod_i      VARCHAR2(5000);
    --porc
    lv_select_porc       VARCHAR2(5000);
    lv_from_porc         VARCHAR2(5000);
    lv_where_porc        VARCHAR2(5000);
    --porc�i�d���j
    lv_from_porc_po      VARCHAR2(5000);
    lv_where_porc_po     VARCHAR2(5000);
    --omsso
    lv_select_omso       VARCHAR2(5000);
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
    --�W�v���Ԑݒ�
  -- ir_param.exec_year_month := lv_f_date;
    gd_s_date :=  FND_DATE.STRING_TO_DATE(ir_param.exec_year_month || gv_fdy || ' ' || gc_e_time
                                           , gc_char_dt_format);

--    gd_s_date :=  FND_DATE.STRING_TO_DATE(ir_param.exec_year_month  , gc_char_ym_format);
    gd_e_date := LAST_DAY(gd_s_date) + 1;
    gd_e_date := TRUNC(gd_e_date);
    --����݌ɐ��ʂ��擾����ׁA�O���f�[�^�܂őΏۂƂ���B
    gd_s_date :=  ADD_MONTHS(gd_s_date, -1);

    --�O�X���̖���
    gd_prv2_last_date  :=  LAST_DAY(ADD_MONTHS(gd_s_date, -1));
    gd_prv2_dt_chr :=  TO_CHAR(gd_prv2_last_date, gc_char_dt_format);

    --�O���̖���
    gd_prv1_last_date  :=  LAST_DAY(gd_s_date);
    gd_prv1_dt_chr :=  TO_CHAR(gd_prv1_last_date, gc_char_dt_format);

    --�����̌�����
    gd_follow_date :=  gd_e_date;
    gd_flw_dt_chr :=  TO_CHAR(gd_follow_date, gc_char_dt_format);

--
    -- ----------------------------------------------------
    -- �r�d�k�d�b�s�吶��
    -- ----------------------------------------------------
--
    lv_select1 := '  SELECT';
    --�q�ɕʂ�I�������ꍇ�͑q�ɃR�[�h���擾����B
    IF (ir_param.print_kind = gc_print_type1) THEN
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
              || ',trn.trans_id            trans_id'           --TRANS_ID
              || ',xleiv.item_attribute15   cost_mng_clss'     -- �����Ǘ��敪
              || ',xleiv.lot_ctl            lot_ctl'           -- ���b�g�Ǘ�
              || ',xleiv.actual_unit_price  actual_unit_price' -- ���ےP��
              || ',CASE WHEN INSTR(xlvv.attribute1,''' || gv_hifn || ''') = 0'
              || '           THEN '''''
              || '      WHEN xrpmxv.rcv_pay_div = ' || gc_rcv_pay_div_in
              || '           THEN SUBSTR(xlvv.attribute1,1,'
              || '                INSTR(xlvv.attribute1,''' || gv_hifn || ''') -1)'
              || '      ELSE'
              || '                SUBSTR(xlvv.attribute1,INSTR(xlvv.attribute1,'''
              ||                                         gv_hifn || ''') +1)'
              || ' END  column_no'                                        -- ���ڈʒu
              || ',trn.reason_code                     reason_code'       -- ���R�R�[�h
              || ',trn.trans_date                      trans_date'        -- �����
              || ',TO_CHAR(trn.trans_date, ''YYYYMM'') trans_ym'          -- ����N��
              || ',xrpmxv.rcv_pay_div       rcv_pay_div'                  -- �󕥋敪
              || ',xrpmxv.dealings_div                 dealings_div'      -- ����敪
              || ',trn.doc_type                        doc_type'          -- �����^�C�v
              || ',xleiv.item_div                      item_div'          -- �i�ڋ敪
              || ',xleiv.prod_div                      prod_div'          -- ���i�敪
              ;
    IF (ir_param.crowd_kind = gc_grp_type3) THEN
      -- �Q��ʁ��u3�F�S�ʁv���w�肳��Ă���ꍇ
      lv_select1 := lv_select1 || ',xleiv.crowd_code                crowd_code'       --�Q�R�[�h
                               || ',SUBSTR(xleiv.crowd_code, 1, 3)  crowd_low'        --���Q
                               || ',SUBSTR(xleiv.crowd_code, 1, 2)  crowd_mid'        --���Q
                               || ',SUBSTR(xleiv.crowd_code, 1, 1)  crowd_high'       --��Q
                               ;
    ELSIF (ir_param.crowd_kind = gc_grp_type4) THEN
      -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
      lv_select1 := lv_select1 || ',xleiv.acnt_crowd_code  crowd_code'               --�o���Q�R�[�h
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 3)  crowd_low'   --���Q
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 2)  crowd_mid'   --���Q
                               || ',SUBSTR(xleiv.acnt_crowd_code, 1, 1)  crowd_high'  --��Q
                               ;
    END IF;
--
    lv_select2 := ''
               || ',trn.item_id              item_id'                                   --�i��ID
               || ',trn.lot_id               lot_id'                                    --���b�gID
               || ',NVL(trn.trans_qty, 0)    trans_qty'                                 --�������
               || ',trn.trans_date           arrival_date'                              --���ד�
               || ',TO_CHAR(trn.trans_date, ''' || gc_char_ym_format || ''') arrival_ym'--���הN��
               || ',xleiv.item_code          item_code'                                --�i�ڃR�[�h
               || ',xleiv.item_short_name    item_name'                                 --�i�ږ���
               ;
    -- ----------------------------------------------------
    -- �e�q�n�l�吶��
    -- ----------------------------------------------------
--
    lv_from :=  ' FROM '
            || ' xxcmn_lot_each_item_v     xleiv'    -- ���b�g�ʕi�ڏ��
            || ',xxcmn_lookup_values2_v    xlvv'     -- �N�C�b�N�R�[�h���view2
            ;
    --�q�ɕʂ�I�������ꍇ�͑q�Ƀ}�X�^����������B
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_from :=  lv_from
              || ',ic_whse_mst               iwm'      -- OPM�q�Ƀ}�X�^
              ;
    END IF;
--
    -- ----------------------------------------------------
    -- �v�g�d�q�d�吶��
    -- ----------------------------------------------------
    lv_where := ' WHERE '
             || ' ((xleiv.start_date_active IS NULL)'
             || '  OR (xleiv.start_date_active IS NOT NULL AND xleiv.start_date_active <= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND ((xleiv.end_date_active IS NULL)'
             || '      OR (xleiv.end_date_active IS NOT NULL AND xleiv.end_date_active >= '
             || '          TRUNC(trn.trans_date)))'
             || ' AND xleiv.item_id    = trn.item_id'
             || ' AND xleiv.lot_id     = trn.lot_id'
             || ' AND xleiv.prod_div   = ''' || ir_param.goods_class || ''''
             || ' AND xleiv.item_div   = ''' || ir_param.item_class  || ''''
             || ' AND xlvv.attribute1 IS NOT NULL'
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
    IF (ir_param.print_kind = gc_print_type1) THEN
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
    IF (ir_param.crowd_kind = gc_grp_type3) THEN
      -- �Q�R�[�h�����͂���Ă���ꍇ
      IF (ir_param.crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.crowd_code  = ''' || ir_param.crowd_code || ''''
                 ;
      END IF;
    END IF;
    ---------------------------------------------------------------------------------------------
    -- �Q��ʁ��u4�F�o���S�ʁv���w�肳��Ă���ꍇ
    IF (ir_param.crowd_kind = gc_grp_type4) THEN
      -- �o���Q�R�[�h�����͂���Ă���ꍇ
       IF (ir_param.acnt_crowd_code  IS NOT NULL) THEN
        lv_where := lv_where
                 || ' AND xleiv.acnt_crowd_code  = ''' || ir_param.acnt_crowd_code || ''''
                 ;
      END IF;
    END IF;
--
    -- ----------------------------------------------------
    -- SQL����( XFER :�o���󕥋敪���u�h�v�ړ��ϑ�����j
    -- ----------------------------------------------------
    lv_from_xfer := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_xfer_v  xrpmxv'   -- ��VIW
      || ',ic_xfer_mst               ixm'      -- �n�o�l�݌ɓ]���}�X�^
      || ',xxinv_mov_req_instr_lines xmril'    -- �ړ��˗��^�w�����ׁi�A�h�I���j
       ;
--
    lv_where_xfer :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_xfer    || '''' --�����^�C�v
      || ' AND trn.reason_code         = ''' || gv_reason_code_xfer || '''' --���R�R�[�h
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
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
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_trni    || '''' --�����^�C�v
      || ' AND trn.reason_code         = ''' || gv_reason_code_trni || '''' --���R�R�[�h
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_type           = xrpmxv.rcv_pay_div'                --���C���^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
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
    -- SQL����(1. ADJI :�o���󕥋敪���u�h�v�݌ɒ���(��)
    -- ----------------------------------------------------
    lv_from_adji := ''
      || ',ic_tran_cmp               trn'      -- �����݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
       ;
--
    lv_where_adji :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_po   || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_hama || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_move || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_othr || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_itm  || ''''
      || ' AND trn.reason_code        <> ''' || gv_reason_code_adji_snt  || ''''
       ;
    -- �r�p�k����(adji)��
    lv_sql_adji := lv_select1 || lv_select2 || lv_from || lv_from_adji
                || lv_where || lv_where_adji;
--
    -- ------------------------------------------------------
    -- SQL����(2. ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�d��)-
    -- ------------------------------------------------------
--
    lv_from_adji_po := ''
      || ',ic_tran_cmp               trn'      -- �����݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_rcv_and_rtn_txns     xrrt'     -- ����ԕi���уA�h�I��
       ;
--
    lv_where_adji_po :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
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
    -- SQL����(3. ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�l��)
    -- ----------------------------------------------------
    lv_from_adji_hm := ''
      || ',ic_tran_cmp               trn'      -- �����݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_namaha_prod_txns     xnpt'     -- ���Z���уA�h�I��
       ;
--
    lv_where_adji_hm :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
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
    -- SQL����(4. ADJI :�o���󕥋敪���u�h�v�݌ɒ���(�ړ�)
    -- ----------------------------------------------------
    lv_from_adji_mv := ''
      || ',ic_tran_cmp               trn'      -- �����݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
      || ',ic_adjs_jnl               iaj'      -- OPM�݌ɒ����W���[�i��
      || ',ic_jrnl_mst               ijm'      -- OPM�W���[�i���}�X�^
      || ',xxpo_vendor_supply_txns   xvst'     -- �O���o��������
       ;
--
    lv_where_adji_mv :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND trn.reason_code         = ''' || gv_reason_code_adji_move || ''''
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
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
    -- SQL����(5. ADJI :�o���󕥋敪���u�h�v�݌ɒ���(���̑����o)
    -- ----------------------------------------------------
    lv_from_adji_snt := ''
      || ',ic_tran_cmp               trn'      -- �����݌Ƀg����
      || ',xxcmn_rcv_pay_mst_adji_v  xrpmxv'   --  ��VIW
       ;
--
    lv_where_adji_snt :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_adji    || '''' --�����^�C�v
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.reason_code         = xrpmxv.reason_code'                --���R�R�[�h
      || ' AND ((trn.reason_code       = ''' || gv_reason_code_adji_itm || ''')'
      || '  OR  (trn.reason_code       = ''' || gv_reason_code_adji_snt || '''))'
      || ' AND xrpmxv.rcv_pay_div      = CASE WHEN trn.trans_qty >= 0 THEN 1 ELSE -1 END'
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
      || ',xxwip_material_detail     xmd'      -- ���Y�����ڍׁi�A�h�I���j
      || ',xxcmn_lookup_values2_v    xlvv2'    -- �N�C�b�N�R�[�h���view2
       ;
--
    lv_where_prod :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
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
      || ' AND trn.item_id             = xmd.item_id'
      || ' AND trn.lot_id              = xmd.lot_id'
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
    -- SQL����(2.PROD :�o���󕥋敪���u�h�v���Y�֘A�iReverse_id�Ȃ��j�i��E�i�ڐU��
    -- ----------------------------------------------------
--
    lv_from_prod_i := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',ic_tran_pnd               trn2'     -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_prod_v  xrpmxv'   --  ��VIW
      || ',xxwip_material_detail     xmd'      -- ���Y�����ڍׁi�A�h�I���j
      || ',xxwip_material_detail     xmd2'     -- ���Y�����ڍׁi�A�h�I���j
      || ',xxcmn_lot_each_item_v     xleiv2'   -- ���b�g�ʕi�ڏ��
      || ',xxcmn_lookup_values2_v    xlvv2'    -- �N�C�b�N�R�[�h���view2
       ;
--
    lv_where_prod_i :=  ''
      || ' AND trn.trans_date >  FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr   || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date <  FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn2.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr   || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn2.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND ((xleiv2.start_date_active IS NULL)'
      || '      OR (xleiv2.start_date_active IS NOT NULL AND xleiv2.start_date_active <= '
      || '          TRUNC(trn2.trans_date)))'
      || ' AND ((xleiv2.end_date_active IS NULL)'
      || '      OR (xleiv2.end_date_active IS NOT NULL AND xleiv2.end_date_active >= '
      || '          TRUNC(trn2.trans_date)))'
      || ' AND trn.doc_type            = ''' || gv_doc_type_prod    || '''' --�����^�C�v
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.reverse_id          IS NULL'
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_type           = xrpmxv.line_type'                  --���C���^�C�v
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --�o�b�`ID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --
      || ' AND trn.item_id             = xmd.item_id'
      || ' AND trn.lot_id              = xmd.lot_id'
      || ' AND trn2.completed_ind      = 1'                                 --�����敪
      || ' AND trn2.reverse_id         IS NULL'
      || ' AND trn2.line_type       = CASE'
      || '                             WHEN trn.line_type = -1 THEN 1'
      || '                             WHEN trn.line_type = 1 THEN -1'
      || '                             END'
      || ' AND xlvv2.meaning IN (''' || gv_dealings_div_prod1 || ''','''
      ||                                gv_dealings_div_prod2 || ''')'       -- �i��U��,�i�ڐU��
      || ' AND xlvv2.lookup_type  = ''' || gc_lookup_type_dealing_div || ''''
      || ' AND xrpmxv.dealings_div         = xlvv2.lookup_code'
      || ' AND (xlvv2.START_DATE_ACTIVE IS NULL OR '
      || '      xlvv2.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (xlvv2.END_DATE_ACTIVE   IS NULL OR '
      || '      xlvv2.END_DATE_ACTIVE   >= TRUNC(trn.trans_date))'
      || ' AND trn.doc_id              = trn2.doc_id'
      || ' AND trn.doc_line            = trn2.doc_line'
      || ' AND trn2.item_id            = xmd2.item_id'
      || ' AND trn2.lot_id             = xmd2.lot_id'
      || ' AND trn2.item_id            = xleiv2.item_id'
      || ' AND trn2.lot_id             = xleiv2.lot_id'
      || ' AND xleiv.item_div = CASE'
      || '                          WHEN trn.line_type = -1 THEN xrpmxv.item_div_origin'
      || '                          WHEN trn.line_type = 1  THEN xrpmxv.item_div_ahead'
      || '                       END'
      || ' AND xleiv2.item_div = CASE'
      || '                          WHEN trn.line_type = 1 THEN xrpmxv.item_div_origin'
      || '                          WHEN trn.line_type = -1 THEN xrpmxv.item_div_ahead'
      || '                       END'
      || ' AND xrpmxv.item_id  = trn.item_id'
       ;
    -- �r�p�k����(prod)Reverse_id�Ȃ��F�i��E�i�ڐU��
    lv_sql_prod_i := lv_select1 || lv_select2 || lv_from || lv_from_prod_i
                  || lv_where || lv_where_prod_i;
--
    -- ----------------------------------------------------
    -- SQL����(1. PORC :�o���󕥋敪���u�h�v�w���֘A    -
    -- ----------------------------------------------------
    lv_select_porc := ''
      || ',NVL( xrpmxv.item_id,trn.item_id)  item_id'  -- �i��ID
      || ',trn.lot_id               lot_id'            -- ���b�gID
      || ',NVL2(xrpmxv.item_id,trn.trans_qty,'
      || ' trn.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div)) trans_qty'-- �������
      || ',trn.trans_date  arrival_date'                            -- ���ד�
      || ',TO_CHAR(trn.trans_date, ''' || gc_char_ym_format || ''') arrival_ym'-- ���הN��
      || ',xitem.item_no            item_code' -- �i�ڃR�[�h
      || ',xitem.item_short_name    item_name' -- �i�ږ���
      ;
--
    lv_from_porc := ''
      || ',ic_tran_pnd                   trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_porc_rma_v  xrpmxv'   -- ��VIW�iRMA�j
      || ',xxcmn_item_mst2_v             xitem'    -- �i�ڃ}�X�^VIEW2
      ;
--
    lv_where_porc :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type            = ''' || gv_doc_type_porc    || '''' --�����^�C�v
      || ' AND trn.completed_ind       = 1'                                 --�����敪
      || ' AND trn.doc_type            = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.doc_id              = xrpmxv.doc_id'                     --�o�b�`ID
      || ' AND trn.doc_line            = xrpmxv.doc_line'                   --����ID
      || ' AND  xitem.item_id          = NVL(xrpmxv.item_id,trn.item_id)'
      || ' AND (XITEM.START_DATE_ACTIVE IS NULL OR '
      || '      XITEM.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (XITEM.END_DATE_ACTIVE   IS NULL OR '
      || '      XITEM.END_DATE_ACTIVE  >= TRUNC(trn.trans_date))'
       ;
    -- �r�p�k����(porc)
    lv_sql_porc := lv_select1 || lv_select_porc || lv_from || lv_from_porc
                || lv_where || lv_where_porc;
--
    -- ----------------------------------------------------
    -- SQL����(2. PORC :�o���󕥋敪���u�h�v�w���֘A�i�d���j
    -- ----------------------------------------------------
    lv_from_porc_po := ''
      || ',ic_tran_pnd                  trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_porc_po_v  xrpmxv'   --  ��VIW�iPO�j
       ;
--
    lv_where_porc_po :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv1_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
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
    lv_select_omso := ''
      || ',NVL( xrpmxv.item_id,trn.item_id)  item_id'  -- �i��ID
      || ',trn.lot_id               lot_id'            -- ���b�gID
      || ',NVL2(xrpmxv.item_id,trn.trans_qty,'
      || ' trn.trans_qty * TO_NUMBER(xrpmxv.rcv_pay_div)) trans_qty'-- �������
      || ',xrpmxv.arrival_date           arrival_date' -- ���ד�
      || ',TO_CHAR(xrpmxv.arrival_date, '''
      || gc_char_ym_format || ''') arrival_ym'         -- ���הN��
      || ',xitem.item_no            item_code'         -- �i�ڃR�[�h
      || ',xitem.item_short_name    item_name'         -- �i�ږ���
      ;
--
    lv_from_omsso := ''
      || ',ic_tran_pnd               trn'      -- �ۗ��݌Ƀg����
      || ',xxcmn_rcv_pay_mst_omso_v  xrpmxv'   -- ��VIW
      || ',xxcmn_item_mst2_v         xitem'    -- �i�ڃ}�X�^VIEW2
       ;
--
    lv_where_omsso :=  ''
      || ' AND trn.trans_date > FND_DATE.STRING_TO_DATE(''' || gd_prv2_dt_chr    || ''',  '''
      ||                                                       gc_char_dt_format || ''')'--�����
      || ' AND trn.trans_date < FND_DATE.STRING_TO_DATE(''' || gd_flw_dt_chr     || ''',  '''
      ||                                                       gc_char_dt_format || ''')'
      || ' AND trn.doc_type         = ''' || gv_doc_type_omso    || '''' --�����^�C�v
      || ' AND trn.completed_ind    = 1'                                 --�����敪
      || ' AND trn.doc_type         = xrpmxv.doc_type'                   --�����^�C�v
      || ' AND trn.line_detail_id   = xrpmxv.doc_line'                   --
      || ' AND  xitem.item_id          = NVL(xrpmxv.item_id,trn.item_id)'
      || ' AND (XITEM.START_DATE_ACTIVE IS NULL OR '
      || '      XITEM.START_DATE_ACTIVE <= TRUNC(trn.trans_date))'
      || ' AND (XITEM.END_DATE_ACTIVE   IS NULL OR '
      || '      XITEM.END_DATE_ACTIVE  >= TRUNC(trn.trans_date))'
       ;
    -- �r�p�k����(OMSO)
    lv_sql_omsso := lv_select1 || lv_select_omso || lv_from || lv_from_omsso
                 || lv_where || lv_where_omsso;
--
    -- ----------------------------------------------------
    -- �n�q�c�d�q  �a�x�吶��
    -- ----------------------------------------------------
    -- ���[��ʁ��P�F�q�ɕʁE�i�ڕʂ̏ꍇ
    IF (ir_param.print_kind = gc_print_type1) THEN
      lv_order_by := ' ORDER BY'
                  || ' h_whse_code'     -- �w�b�_�F�q�ɃR�[�h
                  || ',crowd_code'      -- �Q�R�[�h
                  || ',item_code'       -- �i�ڃR�[�h
                  ;
    ELSE
      lv_order_by := ' ORDER BY'
                  || ' crowd_code'      -- �Q�R�[�h
                  || ',item_code'       -- �i�ڃR�[�h
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
      ;
    lv_sql2 := ''
      ||  ' UNION ALL '
      ||  lv_sql_adji_snt
      ||  ' UNION ALL '
      ||  lv_sql_prod
      ||  ' UNION ALL '
      ||  lv_sql_prod_i
       ;
    lv_sql3 := ''
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
    OPEN lc_ref FOR lv_sql || lv_sql2 || lv_sql3 || lv_order_by;
    -- �o���N�t�F�b�`
    FETCH lc_ref BULK COLLECT INTO ot_data_rec;
    -- �J�[�\���N���[�Y
    CLOSE lc_ref;

--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data;
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
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init           VARCHAR2(100) DEFAULT '*';            -- �����l
    lc_break_null           VARCHAR2(100) DEFAULT '**';           -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_whse_code            VARCHAR2(30) DEFAULT lc_break_init;  -- �q�ɃR�[�h
    lv_crowd_high           VARCHAR2(30) DEFAULT lc_break_init;  -- ��Q�R�[�h
    lv_crowd_mid            VARCHAR2(30) DEFAULT lc_break_init;  -- ���Q�R�[�h
    lv_crowd_low            VARCHAR2(30) DEFAULT lc_break_init;  -- ���Q�R�[�h
    lv_crowd_dtl            VARCHAR2(30) DEFAULT lc_break_init;  -- �Q�R�[�h
    lv_item_code            VARCHAR2(30) DEFAULT lc_break_init;  -- �i�ڃR�[�h
--
    -- �v�Z�p
    in_hifn_position        NUMBER       DEFAULT 0;              -- �v�Z�p�F�|�W�V����
    ln_i                    NUMBER       DEFAULT 0;              -- �J�E���^�[�p
    ln_price                NUMBER       DEFAULT 0;              -- �����p
    in_hifn_pos             NUMBER       DEFAULT 0;              -- ��ʒu
    --�߂�l
    lb_sts                  BOOLEAN       DEFAULT TRUE;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION;             -- �擾���R�[�h�Ȃ�
--
    -------------------------
    --1.�i�ږ��׃N���A����  -
    -------------------------
    PROCEDURE initialize
    IS
    BEGIN
      gn_fst_inv_qty  :=  0;--����݌ɐ���
      gn_fst_inv_amt  :=  0;--����݌ɋ��z
      gn_lst_inv_qty  :=  0;--�I���݌ɐ���
      gn_lst_inv_amt  :=  0;--�I���݌ɋ��z
      <<item_rec_clear>>
      FOR i IN 1 .. gc_print_pos_max LOOP
       qty(i) := 0;
       amt(i) := 0;
      END LOOP  item_rec_clear;
    END initialize;
    ----------------------
    --2.�w�l�k 1�s�o��   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   �^�O�l�[��
      ,ic_type    IN   CHAR                     --   �^�O�^�C�v
      ,iv_data    IN   VARCHAR2 DEFAULT NULL    --   �f�[�^
      ,iv_zero    IN   BOOLEAN  DEFAULT TRUE)   --   �[���T�v���X
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --�f�[�^�̏ꍇ
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        IF (iv_zero = TRUE) THEN
          gt_xml_data_table(gl_xml_idx).tag_value := NVL(iv_data, 0) ; --Null�̏ꍇ�O�\��
        ELSE
          gt_xml_data_table(gl_xml_idx).tag_value := iv_data ;         --Null�ł����̂܂ܕ\��
        END IF;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
--
    ------------------------------------------------
    --3.�݌ɐ��擾(���ی����p) �߂�l�F���� ,���z --
    ------------------------------------------------
    PROCEDURE prc_ac_inv_qty_get(
       ib_stock           IN   BOOLEAN  --TRUE:����  FALSE:�I��
      ,in_pos             IN   NUMBER   --�i�ڃ��R�[�h�z��ʒu
      ,in_price           IN   NUMBER   --����
      ,iv_exec_year_month IN   VARCHAR2 --�����N��
      ,on_inv_qty         OUT  NUMBER   --����
      ,on_inv_amt         OUT  NUMBER)  --���z
    IS
--
      --�݌ɐ��߂�l
      on_inv_qty_tbl NUMBER DEFAULT 0;--�݌Ƀe�[�u�����
      --�݌ɋ��z�߂�l
      on_inv_amt_tbl NUMBER DEFAULT 0;--�݌Ƀe�[�u�����
      --���t�v�Z�p
      ld_invent_date  DATE  DEFAULT FND_DATE.STRING_TO_DATE(
                                      iv_exec_year_month || gv_fdy, gc_char_d_format);
      --�I���N�����o�p
      lv_invent_yyyymm  VARCHAR2(06)  DEFAULT NULL;
--
    BEGIN
      -- �u����v�w��̏ꍇ�͑O���̔N�������߂܂��B
      IF  (ib_stock  =  TRUE)  THEN
        ld_invent_date  :=  TRUNC(ld_invent_date, gv_month_edt) - 1;
        lv_invent_yyyymm  :=  TO_CHAR(ld_invent_date, gc_char_ym_format);
      ELSE
        lv_invent_yyyymm  := iv_exec_year_month;
      END IF;
--
      -- ===============================================================
      -- �I�������݌Ƀe�[�u�����u�O�����݌ɐ��v�u���z�v���擾���܂��B=
      -- ===============================================================
      -- �q�ɕʂ̏ꍇ�͑q�ɖ��̒I�����擾����B
      IF  (gt_body_data(in_pos).whse_code IS NOT NULL) THEN
        BEGIN
          SELECT  SUM(stc.monthly_stock) AS stock
                 ,SUM(stc.monthly_stock * in_price) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND  stc.item_id    = gt_body_data(in_pos).item_id
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
        END;
      -- �i�ڕʂ̏ꍇ�͕i�ڂ̍��v�I�����擾����B
      ELSE
        BEGIN
          SELECT  SUM(stc.monthly_stock) AS stock
                 ,SUM(stc.monthly_stock * in_price) AS stock_amt
          INTO   on_inv_qty_tbl
                ,on_inv_amt_tbl
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.item_id    = gt_body_data(in_pos).item_id
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
            on_inv_amt_tbl :=  0;
        END;
      END IF;
--
      on_inv_qty  :=  NVL(on_inv_qty_tbl, 0);
      on_inv_amt  :=  NVL(on_inv_amt_tbl, 0);
      --�I�����m��F�u�I�������݌Ƀe�[�u���̐��ʁ��O�v�͍݌ɂ͂O�Ƃ݂Ȃ��B
      IF  (on_inv_qty = 0) AND (ib_stock  = FALSE) THEN
        on_inv_qty  :=  0;
        on_inv_amt  :=  0;
      END IF;
--
    END prc_ac_inv_qty_get;
--
    ---------------------------------------------
    --4.�݌ɐ��擾(�W�������p) �߂�l�F���� -
    ---------------------------------------------
    FUNCTION fnc_st_inv_qty_get(
       ib_stock           IN   BOOLEAN    --TRUE:���� FALSE:�I��
      ,in_pos             IN   NUMBER     --�i�ڃ��R�[�h�z��ʒu
      ,iv_exec_year_month IN   VARCHAR2)  --�����N��
      RETURN NUMBER
    IS
--
      --�݌ɐ��߂�l
      on_inv_qty_tbl NUMBER DEFAULT 0;--�݌Ƀe�[�u�����
      on_inv_qty_viw NUMBER DEFAULT 0;--��VIW���
      --���t�v�Z�p
      ld_invent_date  DATE  DEFAULT FND_DATE.STRING_TO_DATE(
                                      iv_exec_year_month || gv_fdy, gc_char_d_format);
      --�I���N�����o�p
      lv_invent_yyyymm  VARCHAR2(06)  DEFAULT NULL;
    BEGIN
      -- �u����v�w��̏ꍇ�͑O���̔N�������߂܂��B
      IF  (ib_stock  =  TRUE)  THEN
        ld_invent_date  :=  TRUNC(ld_invent_date, gv_month_edt) - 1;
        lv_invent_yyyymm  :=  TO_CHAR(ld_invent_date, gc_char_ym_format);
--
       -- �u�I���v�w��̏ꍇ�͓����̔N�������߂܂��B
      ELSE
        lv_invent_yyyymm  := iv_exec_year_month;
      END IF;
      -- =======================================================
      -- �I�������݌Ƀe�[�u�����u�O�����݌ɐ��v���擾���܂��B=
      -- =======================================================
      -- �q�ɕʂ̏ꍇ�͑q�ɖ��̍݌ɂ��擾����B
      IF  (gt_body_data(in_pos).whse_code IS NOT NULL) THEN
        BEGIN
          SELECT SUM(stc.monthly_stock) AS stock
          INTO   on_inv_qty_tbl
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.whse_code    = gt_body_data(in_pos).whse_code
          AND    stc.item_id    = gt_body_data(in_pos).item_id
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
        END;
      ELSE
        BEGIN
          SELECT SUM(stc.monthly_stock) AS stock
          INTO   on_inv_qty_tbl
          FROM   xxinv_stc_inventory_month_stck stc
          WHERE  stc.item_id    = gt_body_data(in_pos).item_id
          AND   stc.invent_ym = lv_invent_yyyymm;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_inv_qty_tbl :=  0;
        END;
      END IF;
--
      RETURN  NVL(on_inv_qty_tbl, 0);
--
    END fnc_st_inv_qty_get;
--
    --------------------------
    --5.���׍��� �w�l�k�o��  -
    --------------------------
    PROCEDURE prc_xml_body_add(
       in_pos             IN  NUMBER    --�i�ڃ��R�[�h�z��ʒu
      ,iv_exec_year_month IN  VARCHAR2  --�����N��
      ,in_price           IN  NUMBER)   --�i�ڌ���
    IS
      --����݌�
      ln_inv_qty        NUMBER DEFAULT 0;--����
      ln_inv_amt        NUMBER DEFAULT 0;--���z
      --�����݌�
      ln_end_stock_qty  NUMBER DEFAULT 0;--����
      ln_end_stock_amt  NUMBER DEFAULT 0;--���z
      --�I���݌�
      ln_stock_qty      NUMBER DEFAULT 0;--����
      ln_stock_amt      NUMBER DEFAULT 0;--���z
      --
      ln_amt            NUMBER DEFAULT 0;--�������ڋ��z
      ib_stock          BOOLEAN DEFAULT TRUE;
      ib_print          BOOLEAN DEFAULT FALSE;
--
    BEGIN
      -- =====================================================
      -- ���׏o�͕ҏW
      -- =====================================================
--
      --����݌ɐ�
      IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
           AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        prc_ac_inv_qty_get(                             --���ی����̏ꍇ
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_inv_qty
          ,on_inv_amt           =>  ln_inv_amt);
--
          ln_inv_qty  :=  ln_inv_qty  + gn_fst_inv_qty;
          ln_inv_amt  :=  ln_inv_amt  + gn_fst_inv_amt;
      ELSE
        ln_inv_qty  :=  fnc_st_inv_qty_get(             --�W�������̏ꍇ
                           ib_stock
                          ,in_pos
                          ,iv_exec_year_month);
--
        ln_inv_qty  :=  ln_inv_qty  + gn_fst_inv_qty;
        ln_inv_amt  :=  in_price * ln_inv_qty;
      END IF;
      IF  (ln_inv_qty !=  0)  THEN
        prc_xml_add( 'g_item', 'T');
        prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --�i��ID
        prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --�i�ږ���
        prc_xml_add('first_inv_qty', 'D', TO_CHAR(NVL(ln_inv_qty, 0)));--����݌ɐ���
        prc_xml_add('first_inv_amt', 'D', TO_CHAR(NVL(ln_inv_amt, 0)));--����݌ɋ��z
        ib_print  := TRUE;
      END IF;
--
      ln_end_stock_qty  :=  ln_end_stock_qty + ln_inv_qty;
      ln_end_stock_amt  :=  ln_end_stock_amt + ln_inv_amt;
--
      -- ���ڏo�͕ҏW�i����`���o�j
      <<field_edit_loop>>
      FOR i IN 1 .. gc_print_pos_max LOOP
        --���ڏo��
        IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
             AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
        THEN
          ln_amt  :=  NVL(qty(i), 0)  *  in_price;
        ELSE
          ln_amt  :=  NVL(amt(i), 0);                                     --�W�������̏ꍇ
        END IF;
        IF  (qty(i) !=  0)  THEN
          IF  (ib_print = FALSE) THEN
            prc_xml_add( 'g_item', 'T');
            prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --�i��ID
            prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --�i�ږ���
            ib_print  := TRUE;
          END IF;
          prc_xml_add(tag_name(i) || gv_qty_prf, 'D', TO_CHAR(qty(i)), FALSE);
        END IF;
        IF  (ln_amt !=  0)  THEN
          prc_xml_add(tag_name(i) || gv_amt_prf, 'D', TO_CHAR(ln_amt), FALSE);
        END IF;
--
        --�����݌ɏW�v
        IF  (i <  gc_pay_pos_strt)  THEN
          ln_end_stock_qty  :=  ln_end_stock_qty  + qty(i);--����
          ln_end_stock_amt  :=  ln_end_stock_amt  + ln_amt;--���z
        ELSE
          ln_end_stock_qty  :=  ln_end_stock_qty  - qty(i);--����
          ln_end_stock_amt  :=  ln_end_stock_amt  - ln_amt;--���z
        END IF;
      END LOOP  field_edit_loop;
--
      IF  (ln_end_stock_qty !=  0)  THEN
        IF  (ib_print = FALSE) THEN
          prc_xml_add( 'g_item', 'T');
          prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --�i��ID
          prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --�i�ږ���
          ib_print  := TRUE;
        END IF;
        prc_xml_add('end_inv_qty', 'D',   TO_CHAR(NVL(ln_end_stock_qty, 0)));--�����݌ɐ���
        prc_xml_add('end_inv_amt', 'D',   TO_CHAR(NVL(ln_end_stock_amt, 0)));--�����݌ɋ��z
      END IF;
--
      ib_stock  :=  FALSE;
      --�I���݌ɐ�
      IF  (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
           AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        prc_ac_inv_qty_get(                             --���ی����̏ꍇ
           ib_stock             =>  ib_stock
          ,in_pos               =>  in_pos
          ,in_price             =>  in_price
          ,iv_exec_year_month   =>  iv_exec_year_month
          ,on_inv_qty           =>  ln_stock_qty
          ,on_inv_amt           =>  ln_stock_amt);
--
          ln_stock_qty  :=  ln_stock_qty  + gn_lst_inv_qty;
          ln_stock_amt  :=  ln_stock_amt  + gn_lst_inv_amt;
      ELSE
        ln_stock_qty  :=  fnc_st_inv_qty_get(            --�W�������̏ꍇ
                             ib_stock
                            ,in_pos
                            ,iv_exec_year_month);
--
        ln_stock_qty  :=  ln_stock_qty  + gn_lst_inv_qty;
        ln_stock_amt  :=  in_price * ln_stock_qty;
      END IF;
      --�I�������m�肵�Ă���ꍇ�̂ݏo�͂��܂��B
      IF  (ln_stock_qty !=  0)  THEN
        IF  (ib_print = FALSE) THEN
          prc_xml_add( 'g_item', 'T');
          prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --�i��ID
          prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --�i�ږ���
          ib_print  := TRUE;
        END IF;
        prc_xml_add('inv_qty', 'D',       TO_CHAR(NVL(ln_stock_qty, 0)));--�I���݌ɐ���
        prc_xml_add('inv_amt', 'D',       TO_CHAR(NVL(ln_stock_amt, 0)));--�I���݌ɋ��z
        IF  (ln_end_stock_qty !=  0 OR ln_stock_qty != 0)  THEN
          IF  (ib_print = FALSE) THEN
            prc_xml_add( 'g_item', 'T');
            prc_xml_add('item_code', 'D', gt_body_data(in_pos).item_code); --�i��ID
            prc_xml_add('item_name', 'D', gt_body_data(in_pos).item_name); --�i�ږ���
            ib_print  := TRUE;
          END IF;
          prc_xml_add('quantity', 'D',      TO_CHAR((ln_end_stock_qty  - ln_stock_qty)));--���ِ���
          prc_xml_add('amount', 'D',        TO_CHAR((ln_end_stock_amt  - ln_stock_amt)));--���ً��z
        END IF;
      ELSE
        IF  (ib_print = TRUE) THEN
          prc_xml_add('inv_qty', 'D',  0);--�I���݌ɐ���
          prc_xml_add('inv_amt', 'D',  0);--�I���݌ɋ��z
          prc_xml_add('quantity','D',  0);--���ِ���
          prc_xml_add('amount',  'D',  0);--���ً��z
        END IF;
      END IF;
--
      IF  (ib_print = TRUE) THEN
        prc_xml_add( '/g_item', 'T');
      END IF;
--
    END prc_xml_body_add;
--
    ----------------------
    --6.�i�ڂ̌����̎擾 -
    ----------------------
    FUNCTION fnc_item_unit_pric_get(
      in_pos   IN   VARCHAR2)    --�i�ڃ��R�[�h�z��ʒu
      RETURN NUMBER
    IS
--
      --�����߂�l
      on_unit_price NUMBER DEFAULT 0;
--
    BEGIN
      --�����敪(1)���W�������̂Ƃ�
      IF  (   (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_st)
           OR (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_n) )
      THEN
        -- =========================================
        -- �W�������}�X�^���W���P�����擾���܂��B=
        -- =========================================
        BEGIN
          SELECT stnd_unit_price as price
          INTO   on_unit_price
          FROM   xxcmn_stnd_unit_price_v xsup
          WHERE  xsup.item_id    =  gt_body_data(in_pos).item_id
            AND (xsup.start_date_active IS NULL OR
                 xsup.start_date_active  <= TRUNC(gt_body_data(in_pos).trans_date))
            AND (xsup.end_date_active   IS NULL OR
                 xsup.end_date_active    >= TRUNC(gt_body_data(in_pos).trans_date));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            on_unit_price :=  0;
        END;
--
     --�����敪(0)�����ی����̂Ƃ�
      ELSIF (    (NVL(gt_body_data(in_pos).cost_mng_clss, '0') = gc_cost_ac)
             AND (NVL(gt_body_data(in_pos).lot_ctl, '0')       = gc_lot_ctl_y) )
      THEN
        on_unit_price :=  NVL(gt_body_data(in_pos).actual_unit_price, 0);
      ELSE
        on_unit_price :=  0;
      END IF;
--
      RETURN  on_unit_price;
--
    END fnc_item_unit_pric_get;
--
    ----------------------
    --7.�i�ږ��׉��Z���� -
    ----------------------
    PROCEDURE prc_item_sum(
      in_pos        IN   NUMBER           --   �i�ڃ��R�[�h�z��ʒu
     ,in_unit_pric  IN   NUMBER           --   ����
     ,ir_param      IN   rec_param_data)  -- 01.���̓p�����[�^�Q
    IS
      -- *** ���[�J���ϐ� ***
      ln_col_pos     NUMBER DEFAULT 0;  --�󕥋敪���̈󎚈ʒu���l
      ln_qty         NUMBER DEFAULT 0;  --����
      ln_rcv_pay_div NUMBER DEFAULT 0;  --�󕥋敪
    BEGIN
--
      --���ʐݒ�
      ln_qty  :=  NVL(gt_body_data(in_pos).trans_qty, 0);
--
      --�󎚈ʒu(�W�v��ʒu�j�𐔒l�֕ϊ�
      BEGIN
        ln_col_pos  :=  TO_NUMBER(gt_body_data(in_pos).print_pos);
      EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_col_pos :=  0;
      END;
--
      --�󕥋敪�𐔒l�֕ϊ�
      BEGIN
        ln_rcv_pay_div  :=  TO_NUMBER(gt_body_data(in_pos).rcv_pay_div);
      EXCEPTION
      WHEN VALUE_ERROR THEN
        ln_rcv_pay_div :=  0;
      END;
--
      --������̔N�����p�����[�^.�����N�� AND ���ד��̔N��  != �p�����[�^.�����N��
      IF (gt_body_data(in_pos).trans_ym = ir_param.exec_year_month)
        AND ( gt_body_data(in_pos).arrival_ym = ir_param.exec_year_month)  THEN
        ----------------
        --�������׉��Z -
        ----------------
        IF  (ln_col_pos >=  1 ) AND (ln_col_pos <= gc_print_pos_max)  THEN
          --���ʉ��Z(�������̐��ʂ͎󕥋敪�ŕ����`�F���W���Ă����j
          qty(ln_col_pos)  :=  qty(ln_col_pos) +  (ln_qty  *  ln_rcv_pay_div);
          --���z���Z
          amt(ln_col_pos)  :=  amt(ln_col_pos) +  in_unit_pric * (ln_qty  *  ln_rcv_pay_div);
        END IF;
--
      --������̔N�����p�����[�^.�����N���̑O�� AND ���ד��̔N��  = �p�����[�^.�����N��
      ELSIF (gt_body_data(in_pos).trans_ym = TO_CHAR(gd_s_date, gc_char_ym_format))
        AND ( gt_body_data(in_pos).arrival_ym = ir_param.exec_year_month)  THEN
        -----------------------------
        --���񐔗ʂ���ы��z���Z ----
        -----------------------------
        gn_fst_inv_qty  :=  gn_fst_inv_qty  + ln_qty;
        gn_fst_inv_amt  :=  gn_fst_inv_amt  + (ln_qty * in_unit_pric);
--
      --������̔N�����p�����[�^.�����N�� AND ���ד��̔N��  = �p�����[�^.�����N���̗���
      ELSIF (gt_body_data(in_pos).trans_ym = ir_param.exec_year_month)
        AND ( gt_body_data(in_pos).arrival_ym = TO_CHAR(gd_follow_date, gc_char_ym_format))  THEN
        -----------------------------
        --�I�����ʂ���ы��z���Z ----
        -----------------------------
        gn_lst_inv_qty  :=  gn_lst_inv_qty  +  ln_qty;
        gn_lst_inv_amt  :=  gn_fst_inv_amt  + (ln_qty * in_unit_pric);
      END IF;
    END prc_item_sum;
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
       ,ot_data_rec   => gt_body_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_body_data.COUNT = 0 ) THEN
      RAISE no_data_expt;
--
    END IF;
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- ���[�U�[�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
    -- -----------------------------------------------------
    -- ���[�U�[�f�f�[�^�^�O�o��
    -- -----------------------------------------------------
--
    -- ���[�h�c
    prc_xml_add('report_id', 'D', gv_report_id);
    -- ���{��
    prc_xml_add('exec_date', 'D', TO_CHAR( gd_exec_date, gc_char_dt_format ));
    -- �S������
    prc_xml_add('exec_user_dept', 'D', NVL(gv_user_dept, ' '));
    -- �S���Җ�
    prc_xml_add('exec_user_name', 'D', NVL(gv_user_name, ' '));
    --�q�ɕʂ�I�����A�q�ɃR�[�h���w�肳��Ă���ꍇ�́u�q�Ɍv�v�͏o�͂��Ȃ̂Łu�i�ڕʁv�Ƃ��Ă���
    IF ((ir_param.print_kind = gc_print_type1) AND (ir_param.locat_code  IS NOT NULL))
      OR (ir_param.print_kind = gc_print_type2) THEN
      prc_xml_add('print_type', 'D', gc_print_type2);--�i�ڕʂƓ�������
    ELSE
      prc_xml_add('print_type', 'D', gc_print_type1);--�q�ɕʂƓ�������
    END IF;
    -- ���[���
    prc_xml_add('out_div', 'D', ir_param.print_kind);
    -- ���[��ʖ�
    prc_xml_add('out_div_name', 'D', SUBSTRB(gv_print_class_name, 1, 20));
    -- �i�ڋ敪
    prc_xml_add('item_div', 'D', ir_param.item_class);
    -- �i�ڋ敪��
    prc_xml_add('item_div_name', 'D', SUBSTRB(gv_item_class_name, 1, 20));
    -- �����N
    prc_xml_add('exec_year', 'D',  SUBSTR(ir_param.exec_year_month, 1, gc_exec_year_m));
    -- ������
    prc_xml_add('exec_month', 'D', SUBSTR(ir_param.exec_year_month, gc_exec_year_y, gc_m_pos));
    -- �Q���
    prc_xml_add('crowd_div', 'D', ir_param.crowd_kind);
    -- �Q��ʖ�
    prc_xml_add('crowd_div_name', 'D', SUBSTRB(gv_crowd_kind_name, 1, 20));
    -- ���i�敪
    prc_xml_add('prod_div', 'D', ir_param.goods_class);
    -- ���i�敪��
    prc_xml_add('prod_div_name', 'D', SUBSTRB(gv_goods_class_name, 1, 20));
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('/user_info', 'T', NULL);
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T', NULL);
    -- -----------------------------------------------------
    -- �q�ɂk�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('lg_locat', 'T', NULL);
--
    -- �u�Ώۃf�[�^�s�ʒu�v�̏����l�ݒ�
    ln_i  :=  1;
   --=========================================�����v
    <<total_loop>>
    WHILE (ln_i  <= gt_body_data.COUNT)                                            LOOP
      lv_whse_code  :=  NVL(gt_body_data(ln_i).whse_code, lc_break_null);
      prc_xml_add('g_locat', 'T');
      ln_position :=  ln_position + 1;
      prc_xml_add('position', 'D', TO_CHAR(ln_position));
      prc_xml_add('locat_code', 'D', NVL(gt_body_data(ln_i).whse_code, 0));
      prc_xml_add('locat_name', 'D', gt_body_data(ln_i).whse_name);
      prc_xml_add('warehouse_code', 'D', lv_whse_code);
      prc_xml_add('lg_crowd_high', 'T');
      --=============================================�q�ɃR�[�h�J�n
      <<whse_code_loop>>
      WHILE (ln_i  <= gt_body_data.COUNT)
        AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)     LOOP
        lv_crowd_high  :=  NVL(gt_body_data(ln_i).crowd_high, lc_break_null);
        prc_xml_add('g_crowd_high', 'T');
        prc_xml_add('crowd_high', 'D', gt_body_data(ln_i).crowd_high);
        prc_xml_add('lg_crowd_mid', 'T');
        --===============================================��Q�R�[�h�J�n
        <<large_grp_loop>>
        WHILE (ln_i  <= gt_body_data.COUNT)
          AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null )  = lv_whse_code)
          AND (NVL( gt_body_data(ln_i).crowd_high, lc_break_null ) = lv_crowd_high)    LOOP
          lv_crowd_mid  :=  NVL(gt_body_data(ln_i).crowd_mid, lc_break_null);
          prc_xml_add('g_crowd_mid', 'T');
          prc_xml_add('crowd_mid', 'D', gt_body_data(ln_i).crowd_mid);
          prc_xml_add('lg_crowd_low', 'T');
          --================================================���Q�R�[�h�J�n
          <<midle_grp_loop>>
          WHILE (ln_i  <= gt_body_data.COUNT)
            AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
            AND (NVL( gt_body_data(ln_i).crowd_mid, lc_break_null ) = lv_crowd_mid)      LOOP
            lv_crowd_low  :=  NVL(gt_body_data(ln_i).crowd_low, lc_break_null);
            prc_xml_add('g_crowd_low', 'T');
            prc_xml_add('crowd_low', 'D', gt_body_data(ln_i).crowd_low);
            prc_xml_add('lg_crowd_dtl', 'T');
            --====================================================���Q�R�[�h�J�n
            <<minor_grp_loop>>
            WHILE (ln_i  <= gt_body_data.COUNT)
              AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
              AND (NVL( gt_body_data(ln_i).crowd_low, lc_break_null ) = lv_crowd_low)      LOOP
              lv_crowd_dtl  :=  NVL(gt_body_data(ln_i).crowd_code, lc_break_null);
              prc_xml_add('g_crowd_dtl', 'T');
              prc_xml_add('crowd_dtl', 'D', gt_body_data(ln_i).crowd_code);
              prc_xml_add('lg_item', 'T');
              --========================================================�Q�R�[�h�J�n
              <<grp_loop>>
              WHILE (ln_i  <= gt_body_data.COUNT)
                AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                AND (NVL( gt_body_data(ln_i).crowd_code, lc_break_null ) = lv_crowd_dtl)     LOOP
                lv_item_code  :=  NVL( gt_body_data(ln_i).item_code, lc_break_null );
                initialize(); --�i�ږ��׃N���A
                ln_price :=  fnc_item_unit_pric_get(ln_i);--�����擾
                --==========================================================�i�ڊJ�n
                <<item_loop>>
                WHILE (ln_i  <= gt_body_data.COUNT)
                  AND (NVL( gt_body_data(ln_i).whse_code, lc_break_null ) = lv_whse_code)
                  AND (NVL( gt_body_data(ln_i).item_code, lc_break_null ) = lv_item_code)      LOOP
                  --�i�ږ��׉��Z����
                  prc_item_sum(ln_i,  ln_price, ir_param);
                  ln_i  :=  ln_i  + 1; --�����׈ʒu
                END LOOP  item_loop;--======================================�i�ڏI��
                prc_xml_body_add(ln_i - 1,
                  ir_param.exec_year_month, ln_price); --�i�ږ��׏o��
              END LOOP  grp_loop;--=====================================�Q�R�[�h�I��
              prc_xml_add('/lg_item', 'T');
              prc_xml_add('/g_crowd_dtl', 'T');
            END LOOP  minor_grp_loop;--===========================���Q�R�[�h�I��
            prc_xml_add('/lg_crowd_dtl', 'T');
            prc_xml_add('/g_crowd_low',  'T');
          END LOOP  midle_grp_loop;--========================���Q�R�[�h�I��
          prc_xml_add('/lg_crowd_low',  'T');
          prc_xml_add('/g_crowd_mid', 'T');
        END LOOP  large_grp_loop;--======================��Q�R�[�h�I��
        prc_xml_add('/lg_crowd_mid', 'T');
        prc_xml_add('/g_crowd_high', 'T');
      END LOOP  whse_code_loop;--====================�q�Ɍv�I��
      prc_xml_add('/lg_crowd_high', 'T');
      prc_xml_add('/g_locat', 'T');
    END LOOP  total_loop;--====================�����v(ALL END)
--
    prc_xml_add('/lg_locat', 'T');
    prc_xml_add('/data_info', 'T'); --�f�[�^�I��
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' );
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
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_yyyymm               IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_report_type          IN     VARCHAR2    -- 04 : ���[���
     ,iv_whse_code            IN     VARCHAR2    -- 05 : �q�ɃR�[�h
     ,iv_group_type           IN     VARCHAR2    -- 06 : �Q���
     ,iv_group_code           IN     VARCHAR2    -- 07 : �Q�R�[�h
     ,iv_accounting_grp_code  IN     VARCHAR2    -- 08 : �o���Q�R�[�h
     ,ov_errbuf               OUT    VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode              OUT    VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg               OUT    VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(30) := 'submain'; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000);                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data;          -- �p�����[�^��n���p
    lv_f_date               VARCHAR2(20);
--
    lv_xml_string           VARCHAR2(32000);
    ln_retcode              NUMBER;
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
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gv_report_id               := 'XXCMN770001T';         -- ���[ID
    gd_exec_date               := SYSDATE;                -- ���{��
--
    lv_f_date := TO_CHAR(FND_DATE.STRING_TO_DATE(iv_yyyymm , gc_char_ym_format),gc_char_ym_format);
    IF (lv_f_date IS NULL) THEN
      lr_param_rec.exec_year_month := iv_yyyymm;
    ELSE
      lr_param_rec.exec_year_month := lv_f_date;
    END IF;                                                 -- 01 : �����N��     (�K�{)
--
    lr_param_rec.goods_class     := iv_product_class;       -- 02 : ���i�敪    �i�K�{)
    lr_param_rec.item_class      := iv_item_class;          -- 03 : �i�ڋ敪    �i�K�{)
    lr_param_rec.print_kind      := iv_report_type;         -- 04 : ���[���    �i�K�{)
    lr_param_rec.locat_code      := iv_whse_code;           -- 05 : �q�ɃR�[�h  �i�C��)
    lr_param_rec.crowd_kind      := iv_group_type;          -- 06 : �Q���      �i�K�{)
    lr_param_rec.crowd_code      := iv_group_code;          -- 07 : �Q�R�[�h    �i�C��)
    lr_param_rec.acnt_crowd_code := iv_accounting_grp_code; -- 08 : �o���Q�R�[�h�i�C��)
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error)
     OR (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt ;
    END IF;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' );
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '       <msg>' || lv_errmsg || '</msg>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_locat>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>');
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>');
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name );
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' );
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
                          );
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string );
      END LOOP xml_data_table;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' );
--
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
    ov_errbuf  := lv_errbuf;
--
  EXCEPTION
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2    -- �G���[���b�Z�[�W
     ,retcode                 OUT    VARCHAR2    -- �G���[�R�[�h
     ,iv_yyyymm               IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_report_type          IN     VARCHAR2    -- 04 : ���[���
     ,iv_whse_code            IN     VARCHAR2    -- 05 : �q�ɃR�[�h
     ,iv_group_type           IN     VARCHAR2    -- 06 : �Q���
     ,iv_group_code           IN     VARCHAR2    -- 07 : �Q�R�[�h
     ,iv_accounting_grp_code  IN     VARCHAR2    -- 08 : �o���Q�R�[�h
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main'; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000);      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1);         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000);      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_yyyymm               => iv_yyyymm              -- 01 : �����N��
       ,iv_product_class        => iv_product_class       -- 02 : ���i�敪
       ,iv_item_class           => iv_item_class          -- 03 : �i�ڋ敪
       ,iv_report_type          => iv_report_type         -- 04 : ���[���
       ,iv_whse_code            => iv_whse_code           -- 05 : �q�ɃR�[�h
       ,iv_group_type           => iv_group_type          -- 06 : �Q���
       ,iv_group_code           => iv_group_code          -- 07 : �Q�R�[�h
       ,iv_accounting_grp_code  => iv_accounting_grp_code -- 08 : �o���Q�R�[�h
       ,ov_errbuf               => lv_errbuf              -- �G���[�E���b�Z�[�W
       ,ov_retcode              => lv_retcode             -- ���^�[���E�R�[�h#
       ,ov_errmsg               => lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
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
END xxcmn770001c;
/
