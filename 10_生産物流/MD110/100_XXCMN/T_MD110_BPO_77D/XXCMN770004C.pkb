CREATE OR REPLACE PACKAGE BODY xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770004c_stest(body)
 * Description      : �󕥂��̑����у��X�g
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.19
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(D-1)
 *  prc_get_report_data       PROCEDURE : �f�[�^�擾(D-2)
 *  fnc_item_unit_pric_get    FUNCTION  : �W�������̎擾
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/09    1.0   C.Kinjo          �V�K�쐬
 *  2008/05/12    1.1   M.Hamamoto       ���ד��̒��o���s���Ă��Ȃ�
 *  2008/05/16    1.2   T.Endou          �s�ID:5,6,7,8�Ή�
 *                                       5 YYYYM�ł�����ɒ��o�����悤�ɏC��
 *                                       6 �w�b�_�̏o�͓��t�Ɓu�S���F�v�����킹�܂���
 *                                       7 ���[���������[ID���̉��ɂ��܂���
 *                                       8 �i�ڋ敪���́A���i�敪���̂̕����ő咷���l�����܂���
 *  2008/05/28    1.3   Y.Ishikawa       ���b�g�Ǘ��O�̏ꍇ�A���b�g����NULL���o�͂���B
 *  2008/05/30    1.4   Y.Ishikawa       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/13    1.5   T.Endou          ���ד��������ꍇ�́A�\�蒅�ד����g�p����
 *                                       ���Y�����ڍׁi�A�h�I���j��������������O��
 *  2008/06/19    1.6   Y.Ishikawa       ����敪���p�p�A���{�Ɋւ��ẮA�󕥋敪���|���Ȃ�
 *  2008/06/25    1.7   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/07    1.8   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma04_v�v
 *  2008/08/20    1.9   A.Shiina         �����w�E#14�Ή�
 *  2008/10/27    1.10  A.Shiina         T_S_524�Ή�
 *  2008/11/11    1.11  A.Shiina         �ڍs�s��C��
 *  2008/11/19    1.12  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#210�Ή�
 *  2008/12/03    1.14  H.Itou           �{��#384�Ή�
 *  2008/12/04    1.15  T.Miyata         �{��#454�Ή�
 *  2008/12/08    1.16  T.Ohashi         �{�ԏ�Q���l���킹�Ή�
 *  2008/12/11    1.17  N.Yoshida        �{�ԏ�Q580�Ή�
 *  2008/12/13    1.18  T.Ohashi         �{�ԏ�Q580�Ή�
 *  2008/12/14    1.19  N.Yoshida        �{�ԏ�Q669�Ή�
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
  gv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCMN770004C' ;           -- �p�b�P�[�W��
  gv_print_name             CONSTANT VARCHAR2(20) := '�󕥂��̑����у��X�g' ;   -- ���[��
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;          -- �A�v���P�[�V����
--
  ------------------------------
  -- �����Ǘ��敪
  ------------------------------
  gc_cost_ac              CONSTANT VARCHAR2(1) := '0' ;   --���ی���
  gc_cost_st              CONSTANT VARCHAR2(1) := '1' ;   --�W������
--
  ------------------------------
  -- ���b�g�Ǘ��敪
  ------------------------------
  gv_lot_n                CONSTANT xxcmn_lot_each_item_v.lot_ctl%TYPE := 0; -- ���b�g�Ǘ��Ȃ�
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_goods_class  CONSTANT VARCHAR2(100) := '���i�敪' ;
  gc_cat_set_item_class   CONSTANT VARCHAR2(100) := '�i�ڋ敪' ;
--
  ------------------------------
  -- ����敪��
  ------------------------------
  gv_haiki                   CONSTANT VARCHAR2(100) := '�p�p' ;
  gv_mihon                   CONSTANT VARCHAR2(100) := '���{' ;
-- 2008/11/11 v1.11 ADD START
  gv_d_name_trn_rcv          CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֗L��_���';
  gv_d_name_item_trn_rcv     CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '���i�U�֗L��_���';
  gv_d_name_trn_ship_rcv_gen CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֏o��_���_��';
  gv_d_name_trn_ship_rcv_han CONSTANT xxcmn_lookup_values_v.meaning%TYPE := '�U�֏o��_���_��';
  gc_rcv_pay_div_adj         CONSTANT VARCHAR2(2) := '-1' ;  --����
-- 2008/11/11 v1.11 ADD END
--
  ------------------------------
  -- ���t���ڕҏW�֘A
  ------------------------------
  gc_char_d_format        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD' ;
  gc_char_m_format        CONSTANT VARCHAR2(30) := 'YYYYMM' ;
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
  gn_one                 CONSTANT NUMBER        := 1   ;
  gn_two                 CONSTANT NUMBER        := 2   ;
  gc_ja                  CONSTANT VARCHAR2( 5) := 'JA' ;
  ------------------------------
  -- ���l�E���z�����_�ʒu
  ------------------------------
  gn_quantity_decml        NUMBER  := 3;
  gn_amount_decml          NUMBER  := 0;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD(
      exec_year_month     VARCHAR2(7)                             -- �����N��
     ,goods_class         mtl_categories_b.segment1%TYPE          -- ���i�敪
     ,item_class          mtl_categories_b.segment1%TYPE          -- �i�ڋ敪
     ,div_type1           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�P
     ,div_type2           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�Q
     ,div_type3           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�R
     ,div_type4           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�S
     ,div_type5           xxcmn_rcv_pay_mst.new_div_account%TYPE  -- �󕥋敪�T
     ,reason_code         sy_reas_cds_tl.reason_code%TYPE         -- ���R�R�[�h
    ) ;
--
  -- ���у��X�g�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD(
      div_tocode         VARCHAR2(100)                                 -- �󕥐�R�[�h
     ,div_toname         VARCHAR2(100)                                 -- �󕥐於
     ,h_reason_code      gmd_routings_b.attribute14%TYPE               -- ���R�R�[�h
     ,h_reason_name      sy_reas_cds_tl.reason_desc1%TYPE              -- ���R�R�[�h��
     ,dept_code          oe_order_headers_all.attribute11%TYPE         -- ���ѕ����R�[�h
     ,dept_name          xxcmn_locations2_v.location_short_name%TYPE   -- ���ѕ�����
     ,trans_date         DATE                                          -- �����
     ,h_div_code         xxcmn_rcv_pay_mst.new_div_account%TYPE        -- �󕥋敪
     ,h_div_name         fnd_lookup_values.meaning%TYPE                -- �󕥋敪��
     ,item_id            ic_item_mst_b.item_id%TYPE                    -- �i�ڂh�c
     ,h_item_code        ic_item_mst_b.item_no%TYPE                    -- �i�ڃR�[�h
     ,h_item_name        xxcmn_item_mst_b.item_short_name%TYPE         -- �i�ږ�
     ,locat_code         mtl_item_locations.segment1%TYPE              -- �q�ɃR�[�h
     ,locat_name         mtl_item_locations.description%TYPE           -- �q�ɖ�
     ,wip_date           ic_lots_mst.attribute1%TYPE                   -- ������
     ,lot_no             ic_lots_mst.lot_no%TYPE                       -- ���b�gNo
     ,original_char      ic_lots_mst.attribute2%TYPE                   -- �ŗL�L��
     ,use_by_date        ic_lots_mst.attribute3%TYPE                   -- �ܖ�����
     ,cost_kbn           ic_item_mst_b.attribute15%TYPE                -- �����Ǘ��敪
     ,lot_kbn            xxcmn_lot_each_item_v.lot_ctl%TYPE            -- ���b�g�Ǘ��敪
     ,actual_unit_price  xxcmn_lot_cost.unit_ploce%TYPE                -- ���ی���
     ,trans_qty          ic_tran_pnd.trans_qty%TYPE                    -- �������
     ,description        ic_lots_mst.attribute18%TYPE                  -- �E�v
   ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �w�b�_���擾�p
  ------------------------------
-- ���[���
  gv_user_dept              xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name              per_all_people_f.per_information18%TYPE;          -- �S����
  gv_goods_class_name       mtl_categories_tl.description%TYPE;               -- ���i�敪��
  gv_item_class_name        mtl_categories_tl.description%TYPE;               -- �i�ڋ敪��
  gv_reason_name            sy_reas_cds_tl.reason_desc1%TYPE;                 -- ���R�R�[�h��
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
   * Description      : �O����(D-1)
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
    -- -------------------------------
    -- �G���[���b�Z�[�W�o�͗p
    -- -------------------------------
    -- �G���[�R�[�h
    lc_err_code        CONSTANT VARCHAR2(100) := 'APP-XXCMN-10010' ;
    -- �g�[�N����
    lc_token_name_01   CONSTANT VARCHAR2(100) := 'PARAMETER' ;
    lc_token_name_02   CONSTANT VARCHAR2(100) := 'VALUE' ;
    -- �g�[�N���l
    lc_token_value     CONSTANT VARCHAR2(100) := '�����N��' ;
--
    -- *** ���[�J���ϐ� ***
    -- -------------------------------
    -- �G���[�n���h�����O�p
    -- -------------------------------
    ln_ret_num                NUMBER ;        -- ���ʊ֐��߂�l�F���l�^
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
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
-- 2008/10/27 v1.10 UPDATE START
--      SELECT cat.description
--      INTO   gv_goods_class_name
--      FROM   xxcmn_categories_v cat
--      WHERE  cat.category_set_name = gc_cat_set_goods_class
--      AND    cat.segment1          = ir_param.goods_class
--      ;
--
      SELECT mct.description
      INTO   gv_goods_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'))
      AND    mcb.segment1         = ir_param.goods_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/27 v1.10 UPDATE END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- �i�ڋ敪�擾
    -- ====================================================
    BEGIN
-- 2008/10/27 v1.10 UPDATE START
--      SELECT cat.description
--      INTO   gv_item_class_name
--      FROM   xxcmn_categories_v cat
--      WHERE  cat.category_set_name = gc_cat_set_item_class
--      AND    cat.segment1          = ir_param.item_class
--      ;
--
      SELECT mct.description
      INTO   gv_item_class_name
      FROM   mtl_category_sets_b mcsb
            ,mtl_categories_b mcb
            ,mtl_categories_tl mct
      WHERE  mcsb.structure_id    = mcb.structure_id
      AND    mcsb.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
      AND    mcb.segment1         = ir_param.item_class
      AND    mcb.category_id      = mct.category_id
      AND    mct.language         = 'JA'
      ;
-- 2008/10/27 v1.10 UPDATE END
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END ;
--
    -- ====================================================
    -- ���R�R�[�h���擾
    -- ====================================================
    gv_reason_name := NULL;
    IF ( ir_param.reason_code IS NOT NULL ) THEN
      BEGIN
        SELECT sy.reason_desc1
        INTO   gv_reason_name
        FROM   sy_reas_cds_tl sy
        WHERE  sy.reason_code   = ir_param.reason_code
          AND  sy.language = gc_ja
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END ;
    END IF;
--
    -- ====================================================
    -- �����N��
    -- ====================================================
    -- ���t�ϊ��`�F�b�N
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymm( ir_param.exec_year_month ) ;
    BEGIN
      IF ( ln_ret_num = 1 ) THEN
        RAISE parameter_check_expt ;
      END IF ;
    EXCEPTION
      --*** �p�����[�^�`�F�b�N��O ***
      WHEN parameter_check_expt THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg( iv_application   => gc_application
                                              ,iv_name          => lc_err_code
                                              ,iv_token_name1   => lc_token_name_01
                                              ,iv_token_name2   => lc_token_name_02
                                              ,iv_token_value1  => lc_token_value
                                              ,iv_token_value2  => ir_param.exec_year_month ) ;
        ov_errmsg  := lv_errmsg ;
        ov_errbuf  := lv_errmsg ;
        ov_retcode := gv_status_error ;
    END;
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
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(D-2)
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
    cn_prod_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id          CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cv_reason_911             CONSTANT VARCHAR2(5) := 'X911';
    cv_reason_912             CONSTANT VARCHAR2(5) := 'X912';
    cv_reason_921             CONSTANT VARCHAR2(5) := 'X921';
    cv_reason_922             CONSTANT VARCHAR2(5) := 'X922';
    cv_reason_941             CONSTANT VARCHAR2(5) := 'X941';
    cv_reason_931             CONSTANT VARCHAR2(5) := 'X931';
    cv_reason_932             CONSTANT VARCHAR2(5) := 'X932';
-- 2008/11/19 v1.12 ADD START
    cv_reason_952             CONSTANT VARCHAR2(5) := 'X952';
    cv_reason_953             CONSTANT VARCHAR2(5) := 'X953';
    cv_reason_954             CONSTANT VARCHAR2(5) := 'X954';
    cv_reason_955             CONSTANT VARCHAR2(5) := 'X955';
    cv_reason_956             CONSTANT VARCHAR2(5) := 'X956';
    cv_reason_957             CONSTANT VARCHAR2(5) := 'X957';
    cv_reason_958             CONSTANT VARCHAR2(5) := 'X958';
    cv_reason_959             CONSTANT VARCHAR2(5) := 'X959';
    cv_reason_960             CONSTANT VARCHAR2(5) := 'X960';
    cv_reason_961             CONSTANT VARCHAR2(5) := 'X961';
    cv_reason_962             CONSTANT VARCHAR2(5) := 'X962';
    cv_reason_963             CONSTANT VARCHAR2(5) := 'X963';
    cv_reason_964             CONSTANT VARCHAR2(5) := 'X964';
    cv_reason_965             CONSTANT VARCHAR2(5) := 'X965';
    cv_reason_966             CONSTANT VARCHAR2(5) := 'X966';
-- 2008/11/19 v1.12 ADD END
--
    cv_div_type    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_NEW_ACCOUNT_DIV';
    cv_out_flag    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_MONTH_TRANS_OUTPUT_FLAG';
    cv_line_type   CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_LINE_TYPE';
    cv_deal_div    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCMN_DEALINGS_DIV';
    cv_yes                  CONSTANT VARCHAR2( 1) := 'Y' ;
    cv_doc_type_porc        CONSTANT VARCHAR2(10) := 'PORC' ;
    cv_doc_type_omso        CONSTANT VARCHAR2(10) := 'OMSO' ;
    cv_doc_type_prod        CONSTANT VARCHAR2(10) := 'PROD' ;
    cv_doc_type_xfer        CONSTANT VARCHAR2(10) := 'XFER' ;
    cv_doc_type_trni        CONSTANT VARCHAR2(10) := 'TRNI' ;
    cv_doc_type_adji        CONSTANT VARCHAR2(10) := 'ADJI' ;
    cv_po                   CONSTANT VARCHAR2(10) := 'PO' ;
    cv_ship_type            CONSTANT VARCHAR2( 2) := '1' ;
    cv_pay_type             CONSTANT VARCHAR2( 2) := '2' ;
    cv_comp_flg             CONSTANT VARCHAR2( 2) := '1' ;
    cv_ovlook_pay           CONSTANT VARCHAR2(10) := 'X942' ; -- �َ��i�ڕ��o
-- 2008/10/27 v1.10 ADD START
    cv_ovlook_rcv           CONSTANT VARCHAR2(10) := 'X943' ; -- �َ��i�ڎ��
    cv_sonota_rcv           CONSTANT VARCHAR2(10) := 'X950' ; -- ���̑����
-- 2008/10/27 v1.10 ADD END
    cv_sonota_pay           CONSTANT VARCHAR2(10) := 'X951' ; -- ���̑����o
    cv_move_result          CONSTANT VARCHAR2(10) := 'X122' ; -- �ړ�����
    cv_vendor_rma           CONSTANT VARCHAR2( 5) := 'X201' ; -- �d����ԕi
    cv_hamaoka_rcv          CONSTANT VARCHAR2( 5) := 'X988' ; -- �l�����
    cv_party_inv            CONSTANT VARCHAR2( 5) := 'X977' ; -- �����݌�
    cv_move_correct         CONSTANT VARCHAR2( 5) := 'X123' ; -- �ړ����ђ���
-- 2008/11/11 v1.11 ADD START
    cv_prod_use           CONSTANT VARCHAR2(10) := 'X952'; --�����g�p
    cv_from_drink         CONSTANT VARCHAR2(10) := 'X953'; -- �h�����N���
    cv_to_drink           CONSTANT VARCHAR2(10) := 'X954'; -- �h�����N��
    cv_set_arvl           CONSTANT VARCHAR2(10) := 'X955'; -- �Z�b�g�g����
    cv_set_ship           CONSTANT VARCHAR2(10) := 'X956'; -- �Z�b�g�g�o��
    cv_dis_arvl           CONSTANT VARCHAR2(10) := 'X957'; -- ��̓���
    cv_dis_ship           CONSTANT VARCHAR2(10) := 'X958'; -- ��̏o��
    cv_oki_rcv            CONSTANT VARCHAR2(10) := 'X959'; -- ����H����
    cv_oki_pay            CONSTANT VARCHAR2(10) := 'X960'; -- ����H�ꕥ�o
    cv_item_mov_arvl      CONSTANT VARCHAR2(10) := 'X961'; -- �i��ړ�����
    cv_item_mov_ship      CONSTANT VARCHAR2(10) := 'X962'; -- �i��ړ��o��
    cv_to_leaf            CONSTANT VARCHAR2(10) := 'X963'; -- ���[�t��
    cv_from_leaf          CONSTANT VARCHAR2(10) := 'X964'; -- ���[�t���
-- 2008/11/11 v1.11 ADD END
    cv_div_pay              CONSTANT VARCHAR2( 2) := '-1' ;
    cv_div_rcv              CONSTANT VARCHAR2( 2) := '1' ;
    lc_f_day                CONSTANT VARCHAR2(2)  := '01';
    lc_f_time               CONSTANT VARCHAR2(10) := ' 00:00:00';
    lc_e_time               CONSTANT VARCHAR2(10) := ' 23:59:59';
    cv_div_kind_transfer    CONSTANT VARCHAR2(10) := '�i��U��';   -- ����敪�F�i��U��
    cv_div_item_transfer    CONSTANT VARCHAR2(10) := '�i�ڐU��';   -- ����敪�F�i�ڐU��
    cv_line_type_material   CONSTANT VARCHAR2( 2) := '1';     -- ���C���^�C�v�F����
    cv_line_type_product    CONSTANT VARCHAR2( 2) := '-1';    -- ���C���^�C�v�F���i
-- 2008/10/24 v1.10 ADD START
    cv_start_date           CONSTANT VARCHAR2(20) := '1900/01/01';
    cv_end_date             CONSTANT VARCHAR2(20) := '9999/12/31';
-- 2008/10/24 v1.10 ADD END
--
    -- *** ���[�J���E�ϐ� ***
    lv_sql1        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql2        VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    -- ��View
    lv_sql_xfer        VARCHAR2(9000);
    lv_sql_trni        VARCHAR2(9000);
    lv_sql_adji1       VARCHAR2(9000);
    lv_sql_adji2       VARCHAR2(9000);
    lv_sql_adji_x201   VARCHAR2(9000);
    lv_sql_adji_x988   VARCHAR2(9000);
    lv_sql_adji_x123   VARCHAR2(9000);
    lv_sql_prod1       VARCHAR2(9000);
    lv_sql_prod2       VARCHAR2(9000);
    lv_sql_porc1       VARCHAR2(9000);
    lv_sql_porc2       VARCHAR2(9000);
    lv_sql_omso        VARCHAR2(9000);
    lv_sql_para        VARCHAR2(2000);
    lv_select          VARCHAR2(2000);
    lv_from            VARCHAR2(2000);
    lv_where           VARCHAR2(2000);
    lv_order_by        VARCHAR2(2000);
    --�ϑ�����(xfer)
    lv_select_xfer     VARCHAR2(3000);
    lv_from_xfer       VARCHAR2(3000);
    lv_where_xfer      VARCHAR2(3000);
    --�ϑ��Ȃ�(trni)
    lv_select_trni     VARCHAR2(3000);
    lv_from_trni       VARCHAR2(3000);
    lv_where_trni      VARCHAR2(3000);
    --���Y�֘A(adji)
    lv_select_adji     VARCHAR2(3000);
    lv_from_adji       VARCHAR2(3000);
    lv_where_adji      VARCHAR2(3000);
    --�݌Ɋ֘A(prod)
    lv_select_prod     VARCHAR2(3000);
    lv_from_prod       VARCHAR2(3000);
    lv_where_prod      VARCHAR2(5000);
    --�w���֘A(porc)
    lv_select_porc     VARCHAR2(3000);
    lv_from_porc       VARCHAR2(3000);
    lv_where_porc      VARCHAR2(3000);
    --�󒍊֘A(omso)
    lv_select_omso     VARCHAR2(3000);
    lv_from_omso       VARCHAR2(3000);
    lv_where_omso      VARCHAR2(3000);
--  ���o�p�J�n�I�����t
    ld_start_date      DATE;
    ld_end_date        DATE;
    lv_start_date      VARCHAR2(20);
    lv_end_date        VARCHAR2(20);
--
    lt_work_rec        tab_data_type_dtl;
    li_cnt             INTEGER;
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
-- 2008/10/27 v1.10 ADD START
      --�Ώێ󕥋敪�擾�J�[�\��
      CURSOR get_div_type_cur IS
        SELECT ir_param.div_type1 div_type
        FROM   DUAL
        WHERE  ir_param.div_type1 IS NOT NULL
        UNION
        SELECT ir_param.div_type2 div_type
        FROM   DUAL
        WHERE  ir_param.div_type2 IS NOT NULL
        UNION
        SELECT ir_param.div_type3 div_type
        FROM   DUAL
        WHERE  ir_param.div_type3 IS NOT NULL
        UNION
        SELECT ir_param.div_type4 div_type
        FROM   DUAL
        WHERE  ir_param.div_type4 IS NOT NULL
        UNION
        SELECT ir_param.div_type5 div_type
        FROM   DUAL
        WHERE  ir_param.div_type5 IS NOT NULL
        ORDER BY div_type
      ;
--
    -------------------------------------------------
    -- ���R�R�[�h�w��Ȃ�
    -------------------------------------------------
    --�i�ڋ敪:���i
    --NDA:101(���i)
    --DD :102/112(OMSO/PORC)
    CURSOR get_data101p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
--      AND    xola.line_id            = wdd.source_line_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '112'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.16 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd rsl xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.16 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
--      AND    xola.line_id            = rsl.oe_order_line_id
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
--            ,trn.item_id                    item_id
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    xoha.header_id          = ooha.header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(���i)
    --DD :105/108(OMSO/PORC)
    CURSOR get_data102p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11v ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11v ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11v ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11v ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDTE STRAT
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDTE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:103(���i)
    --DD :103(OMSO/PORC)
    CURSOR get_data103p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst  xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:104(���i)
    --�ΏۂȂ�
--
    --NDA:105(���i)
    --DD :107(OMSO/PORC)
    CURSOR get_data105p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 ADD START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 ADD END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:106(���i)
    --DD :109(OMSO/PORC)
    CURSOR get_data106p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:107(���i)
    --DD :104(OMSO/PORC)
    CURSOR get_data107p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE STAET
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:108(���i)
    --�ΏۂȂ�
--
    --NDA:109/111(���i)
    --DD :110/111(OMSO/PORC)
    CURSOR get_data109111p_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --�i�ڋ敪:�������ޔ����i
    --NDA:101/103(�������ޔ����i)
    --DD :101/103(OMSO/PORC)
    CURSOR get_data1013m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xola.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:104(�������ޔ����i)
    --DD :113(OMSO/PORC)
    CURSOR get_data104m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 UPDATE START
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    xrpm.shipment_provision_div = '1'
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:105(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:106(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:107(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:108(�������ޔ����i)
    --DD :106(OMSO/PORC)
    CURSOR get_data108m_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:109(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:111(�������ޔ����i)
    --�ΏۂȂ�
--
    --�i�ڋ敪:�S��
    --NDA:201
    --DD :202(ADJI_PO/PORC_PO)
    CURSOR get_data201_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,trn.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_rcv_and_rtn_txns      xrrt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_vendor_rma
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
      SELECT /*+ leading (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) */
             pv.segment1                div_tocode
            ,xv.vendor_short_name       div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,pha.attribute10            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = pha.attribute10
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,rcv_transactions           rt
            ,po_headers_all             pha
            ,po_vendors                 pv
            ,xxcmn_vendors              xv
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    rsl.source_document_code = 'PO'
      AND    rt.transaction_id       = trn.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    pha.po_header_id        = rsl.po_header_id
      AND    pv.vendor_id            = pha.vendor_id
      AND    xv.vendor_id            = pv.vendor_id
      AND    xv.start_date_active   <= TRUNC(trn.trans_date)
      AND    xv.end_date_active     >= TRUNC(trn.trans_date)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:202/203
    --DD :201/203(OMSO/PORC)
    CURSOR get_data2023_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
    --DD :3nn(PROD)
    CURSOR get_data3nn_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class      <> '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:313/314/315/316
    --DD :3nn70(PROD_70)
    CURSOR get_data3nn70_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class       = '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:401/402
    --DD :401/402(ADJI_MV/TRNI/XFER)
    CURSOR get_data4nn_cur (iv_div_type IN VARCHAR2) IS --ADJI_MV
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/13 v1.18 T.Ohashi mod start
-- 2008/12/11 v1.17 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,ABS(trn.trans_qty) * TO_NUMBER(gc_rcv_pay_div_adj) trans_qty
--            ,NVL(trn.trans_qty,0)       trans_qty
            ,NVL(trn.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/12/11 v1.17 UPDATE END
-- 2008/12/13 v1.18 T.Ohashi mod end
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmrl
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_move_correct
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
-- 2008/11/11 v1.16 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
--                                         WHEN trn.trans_qty < 0 THEN cv_div_rcv
--                                         ELSE xrpm.rcv_pay_div
-- 2008/12/11 v1.17 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
                                         ELSE cv_div_rcv
-- 2008/12/11 v1.17 UPDATE END
-- 2008/11/11 v1.16 UPDATE END
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --XFER
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
      --SELECT /*+ leading (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) */
      SELECT /*+ leading (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,ic_xfer_mst                ixm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_xfer
      AND    xrpm.reason_code        = cv_move_result
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_id              = ixm.transfer_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --TRNI
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
      SELECT /*+ leading (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_trni
      AND    xrpm.reason_code        = cv_move_result
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_type            = iaj.trans_type
      AND    trn.doc_id              = iaj.doc_id
      AND    trn.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.doc_type           = trn.doc_type
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.rcv_pay_div        = trn.line_type
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:501/504/506/507/508
    --DD :5nn(ADJI)
    CURSOR get_data5nn_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/14 v1.18 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:502/503
    --DD :5nn(ADJI/ADJI_SNT)
    CURSOR get_data5023_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --ADJI_SNT
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_ovlook_pay
-- 2008/10/27 v1.10 ADD START
                                      ,cv_ovlook_rcv
                                      ,cv_sonota_rcv
-- 2008/10/27 v1.10 ADD END
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--                                      ,cv_sonota_pay)
                                      ,cv_sonota_pay)
--                                      ,cv_sonota_pay
--                                      ,cv_prod_use
--                                      ,cv_from_drink
--                                      ,cv_to_drink
--                                      ,cv_set_arvl
--                                      ,cv_set_ship
--                                      ,cv_dis_arvl
--                                      ,cv_dis_ship
--                                      ,cv_oki_rcv
--                                      ,cv_oki_pay
--                                      ,cv_item_mov_arvl
--                                      ,cv_item_mov_ship
--                                      ,cv_to_leaf
--                                      ,cv_from_leaf)
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:505/509
    --DD :504/509(ADJI/OMSO/PORC)
    CURSOR get_data5059_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --OMSO
      --SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/03 H.Itou Mod Start �{�ԏ�Q#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = wdd.source_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      UNION ALL --PORC
      --SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/03 H.Itou Mod Start �{�ԏ�Q#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:511
    --DD :511(ADJI_HM)
    CURSOR get_data511_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_namaha_prod_txns      xnpt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xnpt.entry_number       = ijm.attribute1
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_hamaoka_rcv
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    -------------------------------------------------
    -- ���R�R�[�h�w�肠��
    -------------------------------------------------
    --�i�ڋ敪:���i
    --NDA:101(���i)
    --DD :102/112(OMSO/PORC)
    CURSOR get_data101p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
--      AND    xola.line_id            = wdd.source_line_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         IN ('04','08')
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 wdd ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.16 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl hps hcs hp ooha otta trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd rsl xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.16 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
--      AND    xola.line_id            = rsl.oe_order_line_id
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha xrpm trn otta) use_nl(xoha xola iimb gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm trn ooha) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
--            ,trn.item_id                    item_id
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
-- 2008/11/19 v1.12 UPDATE START
--      AND    mcb3.segment1           IN ('1','2','4')
      AND    xola.request_item_code  <> xola.shipping_item_code
-- 2008/11/19 v1.12 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    xoha.header_id          = ooha.header_id
      AND    ooha.header_id          = xoha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
--      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(���i)
    --DD :105/108(OMSO/PORC)
    CURSOR get_data102p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11v ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11v ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11v ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11v ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDTE STRAT
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDTE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:103(���i)
    --DD :103(OMSO/PORC)
    CURSOR get_data103p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst  xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NOT NULL
      AND    xrpm.item_div_origin   IS NOT NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:104(���i)
    --�ΏۂȂ�
--
    --NDA:105(���i)
    --DD :107(OMSO/PORC)
    CURSOR get_data105p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 ADD START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 ADD END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    ooha.header_id          = xoha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic3 mcb3 gic4 mcb4 xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_item_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '1'
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = trn.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '2'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:106(���i)
    --DD :109(OMSO/PORC)
    CURSOR get_data106p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3 gic4 mcb4) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,gmi_item_categories        gic4
            ,mtl_categories_b           mcb4
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    mcb1.segment1           = '2'
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    gic4.item_id            = iimb2.item_id
      AND    gic4.category_set_id    = cn_prod_class_id
      AND    gic4.category_id        = mcb4.category_id
      AND    mcb4.segment1           = '1'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:107(���i)
    --DD :104(OMSO/PORC)
    CURSOR get_data107p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta iimb gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE STAET
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_rcv, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:108(���i)
    --�ΏۂȂ�
--
    --NDA:109/111(���i)
    --DD :110/111(OMSO/PORC)
    CURSOR get_data109111p_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) use_nl (xoha xola iimb gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) use_nl (xoha xola iimb gic2 mcb2 gic1 mcb1 ooha otta rsl trn) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,iimb.item_id                   item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,DECODE(xrpm.dealings_div_name
-- 2008/11/11 v1.11 UPDATE START
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
                   ,gv_d_name_trn_ship_rcv_gen, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
                   ,gv_d_name_trn_ship_rcv_han, trn.trans_qty * TO_NUMBER(gc_rcv_pay_div_adj)
-- 2008/11/11 v1.11 UPDATE END
                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_no            = xola.request_item_code
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = iimb.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           = '5'
      AND    gic3.item_id            = trn.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           IN ('1','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.item_div_origin    IN ('1','4')
-- 2008/11/19 v1.12 ADD START
      AND    xrpm.item_div_origin    = mcb3.segment1
-- 2008/11/19 v1.12 ADD END
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --�i�ڋ敪:�������ޔ����i
    --NDA:101/103(�������ޔ����i)
    --DD :101/103(OMSO/PORC)
    CURSOR get_data1013m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status        IN ('04','08')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    rsl.oe_order_header_id  = xola.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.oe_order_line_id    = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead    IS NULL
      AND    xrpm.item_div_origin   IS NULL
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
-- 2008/11/11 v1.11 ADD END
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('101','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div IN ('1','2')
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:102(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:104(�������ޔ����i)
    --DD :113(OMSO/PORC)
    CURSOR get_data104m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             hca.account_number             div_tocode
-- 2008/11/19 v1.12 UPDATE START
            --,xp.party_short_name            div_toname
            ,CASE WHEN hca.customer_class_code = '10' 
                  THEN xp.party_name
                  ELSE xp.party_short_name
             END                            div_toname
-- 2008/11/19 v1.12 UPDATE END
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
            ,hz_parties                 hp
            ,hz_cust_accounts           hca
            ,xxcmn_parties              xp
            ,hz_party_sites             hps
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '1'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/11 v1.11 UPDATE START
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '113'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    hp.party_id             = hca.party_id (+)
      AND    hp.party_id             = xp.party_id (+)
      AND    hp.party_id (+)         = hps.party_id
      AND    hps.party_site_id (+)   = xoha.deliver_to_id
      AND    NVL(xp.start_date_active, FND_DATE.STRING_TO_DATE(cv_start_date, gc_char_d_format))
             <= TRUNC(trn.trans_date)
      AND    NVL(xp.end_date_active, FND_DATE.STRING_TO_DATE(cv_end_date, gc_char_d_format))
             >= TRUNC(trn.trans_date)
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 rsl ooha otta xrpm) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ooha.header_id          = xoha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    xoha.req_status         = '04'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '113'
      AND    otta.attribute1         = '1'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '1'
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:105(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:106(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:107(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:108(�������ޔ����i)
    --DD :106(OMSO/PORC)
    CURSOR get_data108m_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn wdd ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd trn gic1 mcb1 gic2 mcb2 ooha otta xrpm) */
      SELECT /*+ leading (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    wdd.delivery_detail_id  = trn.line_detail_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = wdd.source_header_id
      AND    wdd.source_header_id    = xoha.header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.source_line_id      = xola.line_id
      AND    xoha.header_id          = ooha.header_id
-- 2008/11/11 v1.11 ADD START
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) use_nl (trn rsl ooha otta xrpm gic1 mcb1 gic2 mcb2 xola iimb2 gic3 mcb3) */
--      SELECT /*+ leading (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl trn gic1 mcb1 gic2 mcb2 ooha otta) */
      SELECT /*+ leading (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl trn xrpm ooha otta gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
            ,xxwsh_order_headers_all    xoha
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_item_mst_b              iimb2
            ,gmi_item_categories        gic3
            ,mtl_categories_b           mcb3
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    mcb2.segment1           IN ('1','2','4')
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic3.item_id            = iimb2.item_id
      AND    gic3.category_set_id    = cn_item_class_id
      AND    gic3.category_id        = mcb3.category_id
      AND    mcb3.segment1           = '5'
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xoha.header_id          = ooha.header_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '106'
--      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = '2'
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:109(�������ޔ����i)
    --�ΏۂȂ�
--
    --NDA:111(�������ޔ����i)
    --�ΏۂȂ�
--
    --�i�ڋ敪:�S��
    --NDA:201
    --DD :202(ADJI_PO/PORC_PO)
    CURSOR get_data201_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,trn.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_rcv_and_rtn_txns      xrrt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xrrt.txns_id            = TO_NUMBER(ijm.attribute1)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_vendor_rma
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
      SELECT /*+ leading (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) use_nl (trn rsl rt xrpm gic1 mcb1 gic2 mcb2) */
             pv.segment1                div_tocode
            ,xv.vendor_short_name       div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,pha.attribute10            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = pha.attribute10
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,rcv_transactions           rt
            ,po_headers_all             pha
            ,po_vendors                 pv
            ,xxcmn_vendors              xv
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    rsl.source_document_code = 'PO'
      AND    rt.transaction_id       = trn.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    pha.po_header_id        = rsl.po_header_id
      AND    pv.vendor_id            = pha.vendor_id
      AND    xv.vendor_id            = pv.vendor_id
      AND    xv.start_date_active   <= TRUNC(trn.trans_date)
      AND    xv.end_date_active     >= TRUNC(trn.trans_date)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:202/203
    --DD :201/203(OMSO/PORC)
    CURSOR get_data2023_r_cur (iv_div_type IN VARCHAR2) IS
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn ooha otta xrpm) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/11/11 v1.11 UPDATE START
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb.item_id            = trn.item_id
      AND    iimb.item_id            = ilm.item_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
-- 2008/11/11 v1.11 UPDATE START
--      AND    iimb2.item_no           = xola.request_item_code
      AND    iimb2.item_no           = xola.shipping_item_code
-- 2008/11/11 v1.11 UPDATE END
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
-- 2008/11/11 v1.11 UPDATE START
--      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2008/11/11 v1.11 ADD START
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 ADD END
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
-- 2008/11/11 v1.11 ADD START
      AND    otta.attribute1         = '3'
-- 2008/11/11 v1.11 ADD END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = '3'
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
    --DD :3nn(PROD)
    CURSOR get_data3nn_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class      <> '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:313/314/315/316
    --DD :3nn70(PROD_70)
    CURSOR get_data3nn70_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) use_nl (trn gmd gbh grb xrpm gic1 mcb1 gic2 mcb2) */
             TO_CHAR(xrpm.line_type)    div_tocode
            ,xlv.meaning                div_toname
            ,NULL                       reason_code
            ,NULL                       reason_name
            ,grb.attribute14            post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = grb.attribute14
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                          post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,gme_material_details       gmd
            ,gme_batch_header           gbh
            ,gmd_routings_b             grb
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,ic_whse_mst                iwm
            ,xxcmn_rcv_pay_mst          xrpm
            ,xxcmn_lookup_values2_v     xlv
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_prod
      AND    trn.completed_ind       = cv_comp_flg
      AND    trn.reverse_id          IS NULL
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    gmd.batch_id            = trn.doc_id
      AND    gmd.line_no             = trn.doc_line
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    grb.routing_class       = '70'
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.line_type          = trn.line_type
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd2
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd2.batch_id   = gmd.batch_id
                      AND    gmd2.line_no    = gmd.line_no
                      AND    gmd2.line_type  = -1
                      AND    gic.item_id     = gmd2.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_origin))
      AND    (EXISTS (SELECT 1
                      FROM   gme_material_details gmd3
                            ,gmi_item_categories  gic
                            ,mtl_categories_b     mcb
                      WHERE  gmd3.batch_id   = gmd.batch_id
                      AND    gmd3.line_no    = gmd.line_no
                      AND    gmd3.line_type  = 1
                      AND    gic.item_id     = gmd3.item_id
                      AND    gic.category_set_id = cn_item_class_id
                      AND    gic.category_id = mcb.category_id
                      AND    mcb.segment1    = xrpm.item_div_ahead))
      AND    xlv.lookup_type         = cv_line_type
      AND    xrpm.line_type          = xlv.lookup_code
      AND    (xlv.start_date_active IS NULL OR xlv.start_date_active  <= TRUNC(trn.trans_date))
      AND    (xlv.end_date_active   IS NULL OR xlv.end_date_active    >= TRUNC(trn.trans_date))
      AND    xlv.language            = gc_ja
      AND    xlv.source_lang         = gc_ja
      AND    xlv.enabled_flag        = cv_yes
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:401/402
    --DD :401/402(ADJI_MV/TRNI/XFER)
    CURSOR get_data4nn_r_cur (iv_div_type IN VARCHAR2) IS --ADJI_MV
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) use_nl (xmrih xmrl ijm iaj trn gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmrl ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/13 v1.18 T.Ohashi mod start
-- 2008/12/11 v1.17 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,ABS(trn.trans_qty) * TO_NUMBER(gc_rcv_pay_div_adj) trans_qty
--            ,NVL(trn.trans_qty,0)       trans_qty
            ,NVL(trn.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/11/11 v1.11 UPDATE END
-- 2008/12/11 v1.17 UPDATE END
-- 2008/12/13 v1.18 T.Ohashi mod end
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmrl
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_move_correct
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmrl.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmrl.mov_line_id        = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
-- 2008/11/11 v1.16 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
--                                         WHEN trn.trans_qty < 0 THEN cv_div_rcv
--                                         ELSE xrpm.rcv_pay_div
-- 2008/12/11 v1.17 UPDATE START
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
                                         WHEN trn.trans_qty >= 0 THEN cv_div_pay
                                         ELSE cv_div_rcv
-- 2008/12/11 v1.17 UPDATE END
-- 2008/11/11 v1.16 UPDATE END
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --XFER
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) use_nl (xmrih xmril ixm trn gic2 mcb2 gic1 mcb1 iimb ximb) */
      SELECT /*+ leading (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ixm trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,ic_xfer_mst                ixm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_xfer
      AND    xrpm.reason_code        = cv_move_result
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_id              = ixm.transfer_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --TRNI
-- 2008/11/11 v1.11 UPDATE START
--      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
--      SELECT /*+ leading (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) use_nl (xmrih xmril ijm iaj itc gic2 mcb2 gic1 mcb1 ilm iimb ximb) */
      SELECT /*+ leading (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) use_nl (xmrh xmril ijm iaj trn xrpm gic1 mcb1 gic2 mcb2) */
-- 2008/11/11 v1.11 UPDATE END
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/11/11 v1.11 ADD START
            ,xxinv_mov_req_instr_headers xmrh
-- 2008/11/11 v1.11 ADD END
            ,xxinv_mov_req_instr_lines  xmril
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  xrpm.doc_type           = cv_doc_type_trni
      AND    xrpm.reason_code        = cv_move_result
-- 2008/11/11 v1.11 ADD START
      AND    xmrh.mov_hdr_id         = xmril.mov_hdr_id
-- 2008/11/11 v1.11 ADD END
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xmrh.actual_arrival_date <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/11/11 v1.11 UPDATE END
      AND    trn.doc_type            = iaj.trans_type
      AND    trn.doc_id              = iaj.doc_id
      AND    trn.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
--      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.reason_code        = trn.reason_code
      AND    xrpm.doc_type           = trn.doc_type
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
                                         ELSE cv_div_pay
                                       END
      AND    xrpm.rcv_pay_div        = trn.line_type
-- 2008/11/11 v1.11 UPDATE END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:501/504/506/507/508
    --DD :5nn(ADJI)
    CURSOR get_data5nn_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
--            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/14 v1.18 UPDATE END
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:502/503
    --DD :5nn(ADJI/ADJI_SNT)
    CURSOR get_data5023_r_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --ADJI_SNT
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_ovlook_pay
-- 2008/10/27 v1.10 ADD START
                                      ,cv_ovlook_rcv
                                      ,cv_sonota_rcv
-- 2008/10/27 v1.10 ADD END
-- 2008/10/27 v1.10 ADD START
-- 2008/11/19 v1.12 UPDATE START
-- 2008/11/11 v1.11 UPDATE START
--                                      ,cv_sonota_pay)
                                      ,cv_sonota_pay)
--                                      ,cv_sonota_pay
--                                      ,cv_prod_use
--                                      ,cv_from_drink
--                                      ,cv_to_drink
--                                      ,cv_set_arvl
--                                      ,cv_set_ship
--                                      ,cv_dis_arvl
--                                      ,cv_dis_ship
--                                      ,cv_oki_rcv
--                                      ,cv_oki_pay
--                                      ,cv_item_mov_arvl
--                                      ,cv_item_mov_ship
--                                      ,cv_to_leaf
--                                      ,cv_from_leaf)
-- 2008/11/11 v1.11 UPDATE END
--      AND    xrpm.rcv_pay_div        = CASE
--                                         WHEN trn.trans_qty >= 0 THEN cv_div_rcv
--                                         ELSE cv_div_pay
--                                       END
-- 2008/11/19 v1.12 UPDATE END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:505/509
    --DD :504/509(ADJI/OMSO/PORC)
    CURSOR get_data5059_r_cur (iv_div_type IN VARCHAR2) IS --ADJI
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/14 v1.18 UPDATE START
            ,CASE WHEN xrpm.reason_code = cv_reason_911
                  THEN trn.trans_qty
                  ELSE trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
-- 2008/10/28 v1.11 ADD START
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
-- 2008/10/28 v1.11 ADD END
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
-- 2008/10/28 v1.11 ADD START
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2008/10/28 v1.11 ADD END
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code      IN (cv_reason_911
                                      ,cv_reason_912
                                      ,cv_reason_921
                                      ,cv_reason_922
                                      ,cv_reason_941
                                      ,cv_reason_931
                                      ,cv_reason_932
-- 2008/11/19 v1.12 ADD START
                                      ,cv_reason_952
                                      ,cv_reason_953
                                      ,cv_reason_954
                                      ,cv_reason_955
                                      ,cv_reason_956
                                      ,cv_reason_957
                                      ,cv_reason_958
                                      ,cv_reason_959
                                      ,cv_reason_960
                                      ,cv_reason_961
                                      ,cv_reason_962
                                      ,cv_reason_963
                                      ,cv_reason_964
                                      ,cv_reason_965
                                      ,cv_reason_966)
-- 2008/11/19 v1.12 ADD END
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --OMSO
      --SELECT /*+ leading (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn wdd ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 wdd trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/03 H.Itou Mod Start �{�ԏ�Q#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,wsh_delivery_details       wdd
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_omso
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    wdd.delivery_detail_id  = trn.line_detail_id
      AND    ooha.header_id          = wdd.source_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = wdd.source_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      UNION ALL --PORC
      --SELECT /*+ leading (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (trn rsl ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2) */
      SELECT /*+ leading (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) use_nl (xoha ooha otta xrpm xola iimb2 gic1 mcb1 gic2 mcb2 rsl trn) */
             NULL                           div_tocode
            ,NULL                           div_toname
            ,NULL                           reason_code
            ,NULL                           reason_name
            ,ooha.attribute11               post_code
            ,(SELECT loca.location_short_name
              FROM   xxcmn_locations2_v loca
              WHERE  loca.location_code = ooha.attribute11
              AND    loca.start_date_active <= TRUNC(trn.trans_date)
              AND    loca.end_date_active   >= TRUNC(trn.trans_date)
             )                              post_name
            ,trn.trans_date                 trans_date
            ,xrpm.new_div_account           new_div_account
            ,xlv1.meaning                   div_name
            ,trn.item_id                    item_id
            ,iimb.item_no                   item_code
            ,ximb.item_short_name           item_name
            ,trn.whse_code                  whse_code
            ,iwm.whse_name                  whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
-- 2008/12/03 H.Itou Mod Start �{�ԏ�Q#384
--            ,DECODE(xrpm.dealings_div_name
--                   ,gv_haiki,trn.trans_qty
--                   ,gv_mihon,trn.trans_qty
--                   ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/12/03 H.Itou Mod End
-- 2008/10/27 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,NULL                           lot_desc
-- 2008/10/27 v1.11 UPDATE END
      FROM   ic_tran_pnd                trn
            ,rcv_shipment_lines         rsl
            ,oe_order_headers_all       ooha
            ,oe_transaction_types_all   otta
-- 2008/11/11 v1.11 ADD START
            ,xxwsh_order_headers_all    xoha
-- 2008/11/11 v1.11 ADD END
            ,xxwsh_order_lines_all      xola
            ,ic_item_mst_b              iimb
            ,ic_item_mst_b              iimb2
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = cv_doc_type_porc
      AND    trn.completed_ind       = cv_comp_flg
-- 2008/11/11 v1.11 UPDATE START
--      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
--      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.latest_external_flag = 'Y'
      AND    xoha.arrival_date       >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    xoha.arrival_date       <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    xoha.header_id          = ooha.header_id
      AND    xoha.order_header_id    = xola.order_header_id
-- 2008/11/11 v1.11 UPDATE END
      AND    rsl.shipment_header_id  = trn.doc_id
      AND    rsl.line_num            = trn.doc_line
      AND    ooha.header_id          = rsl.oe_order_header_id
      AND    otta.transaction_type_id = ooha.order_type_id
      AND    xola.line_id            = rsl.oe_order_line_id
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = trn.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    iimb2.item_no           = xola.request_item_code
      AND    gic1.item_id            = iimb2.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = iimb2.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.doc_type           = trn.doc_type
      AND    xrpm.doc_type           = 'PORC'
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_04       IS NOT NULL
      AND    xrpm.new_div_account    = iv_div_type
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
    --NDA:511
    --DD :511(ADJI_HM)
    CURSOR get_data511_r_cur (iv_div_type IN VARCHAR2) IS
      SELECT /*+ leading (xrpm trn gic1 mcb1 gic2 mcb2) use_nl (xrpm trn gic1 mcb1 gic2 mcb2) */
             NULL                       div_tocode
            ,NULL                       div_toname
            ,xrpm.reason_code           reason_code
            ,srct.reason_desc1          reason_name
            ,NULL                       post_code
            ,NULL                       post_name
            ,trn.trans_date             trans_date
            ,xrpm.new_div_account       new_div_account
            ,xlv1.meaning               div_name
            ,trn.item_id                item_id
            ,iimb.item_no               item_code
            ,ximb.item_short_name       item_name
            ,trn.whse_code              whse_code
            ,iwm.whse_name              whse_name
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute1) wip_date
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.lot_no) lot_no
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute2) original_char
            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute3) use_by_date
            ,iimb.attribute15           cost_mng_clss
            ,iimb.lot_ctl               lot_ctl
            ,xlc.unit_ploce             actual_unit_price
            ,trn.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
-- 2008/10/28 v1.11 UPDATE START
--            ,DECODE(iimb.lot_ctl,gv_lot_n,NULL,ilm.attribute18) lot_desc
            ,DECODE(xrpm.use_div_invent_dis
                   ,cv_yes, ijm.attribute2
                   ,NULL)               lot_desc
-- 2008/10/28 v1.11 UPDATE END
      FROM   ic_tran_cmp                trn
            ,ic_adjs_jnl                iaj
            ,ic_jrnl_mst                ijm
            ,xxpo_namaha_prod_txns      xnpt
            ,ic_item_mst_b              iimb
            ,xxcmn_item_mst_b           ximb
            ,ic_lots_mst                ilm
            ,xxcmn_lot_cost             xlc
            ,gmi_item_categories        gic1
            ,mtl_categories_b           mcb1
            ,gmi_item_categories        gic2
            ,mtl_categories_b           mcb2
            ,sy_reas_cds_tl             srct
            ,xxcmn_rcv_pay_mst          xrpm
            ,ic_whse_mst                iwm
            ,xxcmn_lookup_values2_v     xlv1
      WHERE  trn.doc_type            = xrpm.doc_type
      AND    trn.reason_code         = xrpm.reason_code
      AND    trn.trans_date         >= FND_DATE.STRING_TO_DATE(lv_start_date,gc_char_dt_format)
      AND    trn.trans_date         <= FND_DATE.STRING_TO_DATE(lv_end_date,gc_char_dt_format)
      AND    iaj.trans_type          = trn.doc_type
      AND    iaj.doc_id              = trn.doc_id
      AND    iaj.doc_line            = trn.doc_line
      AND    ijm.journal_id          = iaj.journal_id
      AND    xnpt.entry_number       = ijm.attribute1
      AND    ilm.item_id             = trn.item_id
      AND    ilm.lot_id              = trn.lot_id
      AND    iimb.item_id            = ilm.item_id
      AND    xlc.item_id(+)          = ilm.item_id
      AND    xlc.lot_id (+)          = ilm.lot_id
      AND    ximb.item_id            = iimb.item_id
      AND    ximb.start_date_active <= TRUNC(trn.trans_date)
      AND    ximb.end_date_active   >= TRUNC(trn.trans_date)
      AND    gic1.item_id            = trn.item_id
      AND    gic1.category_set_id    = cn_prod_class_id
      AND    gic1.category_id        = mcb1.category_id
      AND    mcb1.segment1           = ir_param.goods_class
      AND    gic2.item_id            = trn.item_id
      AND    gic2.category_set_id    = cn_item_class_id
      AND    gic2.category_id        = mcb2.category_id
      AND    mcb2.segment1           = ir_param.item_class
      AND    xrpm.new_div_account    = iv_div_type
      AND    xrpm.doc_type           = cv_doc_type_adji
      AND    xrpm.reason_code        = cv_hamaoka_rcv
      AND    xrpm.reason_code        = srct.reason_code(+)
      AND    xrpm.break_col_04       IS NOT NULL
      AND    srct.language(+)        = gc_ja
      AND    trn.whse_code           = iwm.whse_code
      AND    xlv1.lookup_type        = cv_div_type
      AND    xrpm.new_div_account    = xlv1.lookup_code
      AND    (xlv1.start_date_active IS NULL
             OR xlv1.start_date_active <= TRUNC(trn.trans_date))
      AND    (xlv1.end_date_active   IS NULL
             OR xlv1.end_date_active   >= TRUNC(trn.trans_date))
      AND    xlv1.language           = 'JA'
      AND    xlv1.source_lang        = 'JA'
      AND    xlv1.enabled_flag       = 'Y'
      AND    xrpm.reason_code        = ir_param.reason_code
      ORDER BY reason_code,item_code,whse_code,lot_no
      ;
--
-- 2008/10/27 v1.10 ADD END
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �W�v���Ԑݒ�
    ld_start_date := FND_DATE.STRING_TO_DATE(ir_param.exec_year_month ||
                                             lc_f_day, gc_char_d_format);
    lv_start_date := TO_CHAR(ld_start_date, gc_char_d_format) || lc_f_time ;
    ld_end_date   := LAST_DAY(ld_start_date);
    lv_end_date   := TO_CHAR(ld_end_date, gc_char_d_format) || lc_e_time ;
--
-- 2008/10/27 v1.10 ADD START
--
    -- ���R�R�[�h�w��Ȃ��̏ꍇ
    IF ( ir_param.reason_code IS NULL ) THEN
--
      <<div_type_loop>>
      FOR get_div_type_rec IN get_div_type_cur LOOP
--
        --���i�̏ꍇ
        IF ( ir_param.item_class = '5' ) THEN
          --�󕥋敪:101
          IF (get_div_type_rec.div_type = '101') THEN
            OPEN  get_data101p_cur(get_div_type_rec.div_type);
            FETCH get_data101p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data101p_cur;
          --�󕥋敪:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            OPEN  get_data102p_cur(get_div_type_rec.div_type);
            FETCH get_data102p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data102p_cur;
          --�󕥋敪:103
          ELSIF (get_div_type_rec.div_type = '103') THEN
            OPEN  get_data103p_cur(get_div_type_rec.div_type);
            FETCH get_data103p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data103p_cur;
          --�󕥋敪:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            NULL; --�ΏۊO
          --�󕥋敪:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            OPEN  get_data105p_cur(get_div_type_rec.div_type);
            FETCH get_data105p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data105p_cur;
          --�󕥋敪:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            OPEN  get_data106p_cur(get_div_type_rec.div_type);
            FETCH get_data106p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data106p_cur;
          --�󕥋敪:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            OPEN  get_data107p_cur(get_div_type_rec.div_type);
            FETCH get_data107p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data107p_cur;
          --�󕥋敪:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            NULL; --�ΏۊO
          --�󕥋敪:109/111
          ELSIF (get_div_type_rec.div_type IN ('109','111')) THEN
            OPEN  get_data109111p_cur(get_div_type_rec.div_type);
            FETCH get_data109111p_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data109111p_cur;
          END IF;
        --�������ޔ����i�̏ꍇ
        ELSE
          --�󕥋敪:101/103
          IF (get_div_type_rec.div_type IN ('101','103')) THEN
            OPEN  get_data1013m_cur(get_div_type_rec.div_type);
            FETCH get_data1013m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data1013m_cur;
          --�󕥋敪:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            NULL; --�ΏۊO
          --�󕥋敪:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            OPEN  get_data104m_cur(get_div_type_rec.div_type);
            FETCH get_data104m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data104m_cur;
          --�󕥋敪:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            NULL; --�ΏۊO
          --�󕥋敪:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            NULL; --�ΏۊO
          --�󕥋敪:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            NULL; --�ΏۊO
          --�󕥋敪:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            OPEN  get_data108m_cur(get_div_type_rec.div_type);
            FETCH get_data108m_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data108m_cur;
          --�󕥋敪:109
          ELSIF (get_div_type_rec.div_type = '109') THEN
            NULL; --�ΏۊO
          --�󕥋敪:111
          ELSIF (get_div_type_rec.div_type = '111') THEN
            NULL; --�ΏۊO
          END IF;
        END IF;
--
        --����
        --�󕥋敪:201
        IF (get_div_type_rec.div_type = '201') THEN
          OPEN  get_data201_cur(get_div_type_rec.div_type);
          FETCH get_data201_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data201_cur;
        --�󕥋敪:202/203
        ELSIF (get_div_type_rec.div_type IN ('202','203')) THEN
          OPEN  get_data2023_cur(get_div_type_rec.div_type);
          FETCH get_data2023_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data2023_cur;
        --�󕥋敪:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
        ELSIF (get_div_type_rec.div_type IN ('301','302','303'
                                            ,'304','305','306'
                                            ,'307','308','309'
                                            ,'310','311','312'
                                            ,'317','318','319')) THEN
          OPEN  get_data3nn_cur(get_div_type_rec.div_type);
          FETCH get_data3nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn_cur;
        --�󕥋敪:313/314/315/316
        ELSIF (get_div_type_rec.div_type IN ('313','314','315','316')) THEN
          OPEN  get_data3nn70_cur(get_div_type_rec.div_type);
          FETCH get_data3nn70_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn70_cur;
        --�󕥋敪:401/402
        ELSIF (get_div_type_rec.div_type IN ('401','402')) THEN
          OPEN  get_data4nn_cur(get_div_type_rec.div_type);
          FETCH get_data4nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data4nn_cur;
        --�󕥋敪:501/504/506/507/508
-- 2008/12/04 v1.15 UPDATE START
--        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508')) THEN
        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508','509')) THEN
-- 2008/12/04 v1.15 UPDATE END
          OPEN  get_data5nn_cur(get_div_type_rec.div_type);
          FETCH get_data5nn_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5nn_cur;
        --�󕥋敪:502/503
        ELSIF (get_div_type_rec.div_type IN ('502','503')) THEN
          OPEN  get_data5023_cur(get_div_type_rec.div_type);
          FETCH get_data5023_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5023_cur;
        --�󕥋敪:505/510
-- 2008/11/29 v1.13 yoshida UPDATE start
        --ELSIF (get_div_type_rec.div_type IN ('505','509')) THEN
        ELSIF (get_div_type_rec.div_type IN ('505','510')) THEN
-- 2008/11/29 v1.13 yoshida UPDATE end
          OPEN  get_data5059_cur(get_div_type_rec.div_type);
          FETCH get_data5059_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5059_cur;
        --�󕥋敪:511
        ELSIF (get_div_type_rec.div_type = '511') THEN
          OPEN  get_data511_cur(get_div_type_rec.div_type);
          FETCH get_data511_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data511_cur;
        END IF;
--
        li_cnt := ot_data_rec.COUNT;
--
        IF  (li_cnt = 0)
        AND (lt_work_rec.COUNT > 0) THEN
          ot_data_rec := lt_work_rec;
        ELSIF (li_cnt > 0)
        AND   (lt_work_rec.COUNT > 0) THEN
          <<set_data_loop>>
          FOR i IN 1..lt_work_rec.COUNT LOOP
            ot_data_rec(li_cnt + i) := lt_work_rec(i);
          END LOOP set_data_loop;
        END IF;
--
        lt_work_rec.DELETE;
--
      END LOOP div_type_loop;
--
    -- ���R�R�[�h�w�肠��̏ꍇ
    ELSE
--
      <<div_type_r_loop>>
      FOR get_div_type_rec IN get_div_type_cur LOOP
--
        --���i�̏ꍇ
        IF ( ir_param.item_class = '5' ) THEN
          --�󕥋敪:101
          IF (get_div_type_rec.div_type = '101') THEN
            OPEN  get_data101p_r_cur(get_div_type_rec.div_type);
            FETCH get_data101p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data101p_r_cur;
          --�󕥋敪:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            OPEN  get_data102p_r_cur(get_div_type_rec.div_type);
            FETCH get_data102p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data102p_r_cur;
          --�󕥋敪:103
          ELSIF (get_div_type_rec.div_type = '103') THEN
            OPEN  get_data103p_r_cur(get_div_type_rec.div_type);
            FETCH get_data103p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data103p_r_cur;
          --�󕥋敪:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            NULL; --�ΏۊO
          --�󕥋敪:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            OPEN  get_data105p_r_cur(get_div_type_rec.div_type);
            FETCH get_data105p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data105p_r_cur;
          --�󕥋敪:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            OPEN  get_data106p_r_cur(get_div_type_rec.div_type);
            FETCH get_data106p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data106p_r_cur;
          --�󕥋敪:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            OPEN  get_data107p_r_cur(get_div_type_rec.div_type);
            FETCH get_data107p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data107p_r_cur;
          --�󕥋敪:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            NULL; --�ΏۊO
          --�󕥋敪:109/111
          ELSIF (get_div_type_rec.div_type IN ('109','111')) THEN
            OPEN  get_data109111p_r_cur(get_div_type_rec.div_type);
            FETCH get_data109111p_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data109111p_r_cur;
          END IF;
        --�������ޔ����i�̏ꍇ
        ELSE
          --�󕥋敪:101/103
          IF (get_div_type_rec.div_type IN ('101','103')) THEN
            OPEN  get_data1013m_r_cur(get_div_type_rec.div_type);
            FETCH get_data1013m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data1013m_r_cur;
          --�󕥋敪:102
          ELSIF (get_div_type_rec.div_type = '102') THEN
            NULL; --�ΏۊO
          --�󕥋敪:104
          ELSIF (get_div_type_rec.div_type = '104') THEN
            OPEN  get_data104m_r_cur(get_div_type_rec.div_type);
            FETCH get_data104m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data104m_r_cur;
          --�󕥋敪:105
          ELSIF (get_div_type_rec.div_type = '105') THEN
            NULL; --�ΏۊO
          --�󕥋敪:106
          ELSIF (get_div_type_rec.div_type = '106') THEN
            NULL; --�ΏۊO
          --�󕥋敪:107
          ELSIF (get_div_type_rec.div_type = '107') THEN
            NULL; --�ΏۊO
          --�󕥋敪:108
          ELSIF (get_div_type_rec.div_type = '108') THEN
            OPEN  get_data108m_r_cur(get_div_type_rec.div_type);
            FETCH get_data108m_r_cur BULK COLLECT INTO lt_work_rec;
            CLOSE get_data108m_r_cur;
          --�󕥋敪:109
          ELSIF (get_div_type_rec.div_type = '109') THEN
            NULL; --�ΏۊO
          --�󕥋敪:111
          ELSIF (get_div_type_rec.div_type = '111') THEN
            NULL; --�ΏۊO
          END IF;
        END IF;
--
        --����
        --�󕥋敪:201
        IF (get_div_type_rec.div_type = '201') THEN
          OPEN  get_data201_r_cur(get_div_type_rec.div_type);
          FETCH get_data201_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data201_r_cur;
        --�󕥋敪:202/203
        ELSIF (get_div_type_rec.div_type IN ('202','203')) THEN
          OPEN  get_data2023_r_cur(get_div_type_rec.div_type);
          FETCH get_data2023_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data2023_r_cur;
        --�󕥋敪:301/302/303/304/305/306/307/308/309/310/311/312/317/318/319
        ELSIF (get_div_type_rec.div_type IN ('301','302','303'
                                            ,'304','305','306'
                                            ,'307','308','309'
                                            ,'310','311','312'
                                            ,'317','318','319')) THEN
          OPEN  get_data3nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data3nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn_r_cur;
        --�󕥋敪:313/314/315/316
        ELSIF (get_div_type_rec.div_type IN ('313','314','315','316')) THEN
          OPEN  get_data3nn70_r_cur(get_div_type_rec.div_type);
          FETCH get_data3nn70_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data3nn70_r_cur;
        --�󕥋敪:401/402
        ELSIF (get_div_type_rec.div_type IN ('401','402')) THEN
          OPEN  get_data4nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data4nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data4nn_r_cur;
        --�󕥋敪:501/504/506/507/508/509
-- 2008/12/04 v1.15 UPDATE START
--        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508')) THEN
        ELSIF (get_div_type_rec.div_type IN ('501','504','506','507','508','509')) THEN
-- 2008/12/04 v1.15 UPDATE END
          OPEN  get_data5nn_r_cur(get_div_type_rec.div_type);
          FETCH get_data5nn_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5nn_r_cur;
        --�󕥋敪:502/503
        ELSIF (get_div_type_rec.div_type IN ('502','503')) THEN
          OPEN  get_data5023_r_cur(get_div_type_rec.div_type);
          FETCH get_data5023_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5023_r_cur;
        --�󕥋敪:505/510
-- 2008/11/29 v1.13 yoshida UPDATE start
        --ELSIF (get_div_type_rec.div_type IN ('505','509')) THEN
        ELSIF (get_div_type_rec.div_type IN ('505','510')) THEN
-- 2008/11/29 v1.13 yoshida UPDATE end
          OPEN  get_data5059_r_cur(get_div_type_rec.div_type);
          FETCH get_data5059_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data5059_r_cur;
        --�󕥋敪:511
        ELSIF (get_div_type_rec.div_type = '511') THEN
          OPEN  get_data511_r_cur(get_div_type_rec.div_type);
          FETCH get_data511_r_cur BULK COLLECT INTO lt_work_rec;
          CLOSE get_data511_r_cur;
        END IF;
--
        li_cnt := ot_data_rec.COUNT;
--
        IF  (li_cnt = 0)
        AND (lt_work_rec.COUNT > 0) THEN
          ot_data_rec := lt_work_rec;
        ELSIF (li_cnt > 0)
        AND   (lt_work_rec.COUNT > 0) THEN
          <<set_data_loop>>
          FOR i IN 1..lt_work_rec.COUNT LOOP
            ot_data_rec(li_cnt + i) := lt_work_rec(i);
          END LOOP set_data_loop;
        END IF;
--
        lt_work_rec.DELETE;
--
      END LOOP div_type_r_loop;
--
    END IF;
--
-- 2008/10/27 v1.10 ADD END
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
   * Procedure Name   : fnc_item_unit_pric_get
   * Description      : �W�������̎擾
   ***********************************************************************************/
  FUNCTION fnc_item_unit_pric_get(
       iv_item_id    IN   VARCHAR2  -- �i�ڂh�c
      ,id_trans_date IN   DATE)     -- �����
      RETURN NUMBER
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_item_unit_pric_get' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    -- �����߂�l
    on_unit_price NUMBER DEFAULT 0;
--
  BEGIN
    -- =========================================
    -- �W�������}�X�^���W���P�����擾���܂��B=
    -- =========================================
    BEGIN
      SELECT stnd_unit_price as price
      INTO   on_unit_price
      FROM   xxcmn_stnd_unit_price_v xsup
      WHERE  xsup.item_id    = iv_item_id
        AND (xsup.start_date_active IS NULL OR
             xsup.start_date_active  <= TRUNC(id_trans_date))
        AND (xsup.end_date_active   IS NULL OR
             xsup.end_date_active    >= TRUNC(id_trans_date));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_unit_price :=  0;
    END;
    RETURN  on_unit_price;
--
  END fnc_item_unit_pric_get;
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
    lc_flg_y                CONSTANT VARCHAR2(1) := 'Y';
    lc_flg_n                CONSTANT VARCHAR2(1) := 'N';
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
    lv_div_code         VARCHAR2(100) DEFAULT lc_break_init ;  -- �󕥋敪
    lv_reason_code      VARCHAR2(100) DEFAULT lc_break_init ;  -- ���R�R�[�h
    lv_item_code        VARCHAR2(100) DEFAULT lc_break_init ;  -- �i�ڃR�[�h
    lv_cost_kbn         VARCHAR2(100) DEFAULT lc_break_init ;  -- �����Ǘ��敪
    lv_locat_code       VARCHAR2(100) DEFAULT lc_break_init ;  -- �q�ɃR�[�h
    lv_lot_no           VARCHAR2(100) DEFAULT lc_break_init ;  -- ���b�gNo
    lv_flg              VARCHAR2(1)   DEFAULT lc_break_init;
--
    -- �v�Z�p
    ln_quantity         NUMBER DEFAULT 0 ;      -- ����
    ln_amount           NUMBER DEFAULT 0 ;      -- ���z
    ln_stand_unit_price NUMBER DEFAULT 0 ;      -- �W������
--
    lr_data_dtl         rec_data_type_dtl;      -- �\����
--
    lb_ret                  BOOLEAN;
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
    ---------------------
    -- XML�^�O�}������
    ---------------------
    PROCEDURE prc_set_xml(
        ic_type              IN        CHAR       -- �^�O�^�C�v  T:�^�O
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
--
    -- ���[�h�c
    prc_set_xml('D', 'report_id', gv_report_id);
    -- ���{��
    prc_set_xml('D', 'exec_date', TO_CHAR(gd_exec_date,gc_char_dt_format));
    -- �S������
    prc_set_xml('D', 'exec_user_dept', gv_user_dept, 10);
    -- �S���Җ�
    prc_set_xml('D', 'exec_user_name', gv_user_name, 14);
    -- �����N��
    prc_set_xml('D', 'exec_year', SUBSTR(ir_param.exec_year_month, 1, 4) );
    prc_set_xml('D', 'exec_month', TO_CHAR( SUBSTR(ir_param.exec_year_month, 5, 2), '00') );
    -- ���i�敪
    prc_set_xml('D', 'prod_div', ir_param.goods_class);
    prc_set_xml('D', 'prod_div_name', gv_goods_class_name, 20);
    -- �i�ڋ敪
    prc_set_xml('D', 'item_div', ir_param.item_class);
    prc_set_xml('D', 'item_div_name', gv_item_class_name, 20);
    -- ���R�R�[�h(�p�����[�^)
    prc_set_xml('D', 'p_reason_code', ir_param.reason_code);
    prc_set_xml('D', 'p_reason_name', gv_reason_name, 20);
    -- -----------------------------------------------------
    -- ���[�U�[�f�I���^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T','/user_info');
    -- -----------------------------------------------------
    -- �f�[�^�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'data_info');
    -- -----------------------------------------------------
    -- �󕥋敪�k�f�J�n�^�O�o��
    -- -----------------------------------------------------
    prc_set_xml('T', 'lg_div');
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    <<main_data_loop>>
    FOR i IN 1..gt_main_data.COUNT LOOP
      -- =====================================================
      -- ���׏o��(���Ŏ�)
      -- =====================================================
      IF  (( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code )
           OR  ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code )
           OR  ( NVL( gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ))
      AND (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
--
        -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
        IF (lv_cost_kbn = gc_cost_st ) THEN
          ln_amount := ln_stand_unit_price * ln_quantity;
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �q��
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- ������
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ���b�g�m��
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- �ŗL�L��
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- �ܖ�����
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- ����
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- �P��
        -- �����Ǘ��敪���u���ی����v�̏ꍇ
        IF (lv_cost_kbn = gc_cost_ac ) THEN
           -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
           -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- �����Ǘ��敪���u�W�������v�̏ꍇ
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- ����ȊO
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- ���o�ɋ��z
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- �󕥐�
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- ���ѕ���
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- �E�v
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ���b�g�f�I���^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
        -- �v�Z���ڏ�����
        ln_quantity := 0;
        ln_amount   := 0;
      END IF;
--
      -- =====================================================
      -- �󕥋敪�u���C�N
      -- =====================================================
      -- �󕥋敪���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_div_code, lc_break_null ) <> lv_div_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_div_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- ���R�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_reason');
          ------------------------------
          -- ���R�R�[�h�k�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_reason');
          ------------------------------
          -- �󕥋敪�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_div');
        END IF ;
--
        -- -----------------------------------------------------
        -- �󕥋敪�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_div');
        -- -----------------------------------------------------
        -- �󕥋敪�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �󕥋敪
        prc_set_xml('D', 'div_code', gt_main_data(i).h_div_code);
        prc_set_xml('D', 'div_name', gt_main_data(i).h_div_name, 20);
        -- -----------------------------------------------------
        -- ���R�R�[�h�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'lg_reason');
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_div_code := NVL( gt_main_data(i).h_div_code, lc_break_null )  ;
        lv_reason_code  := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���R�R�[�h�u���C�N
      -- =====================================================
      -- ���R�R�[�h���؂�ւ�����ꍇ
      IF ( NVL( gt_main_data(i).h_reason_code, lc_break_null ) <> lv_reason_code ) THEN
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF ( lv_reason_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
          ------------------------------
          -- �i�ڂk�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/lg_item');
          ------------------------------
          -- ���R�R�[�h�f�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_reason');
        END IF ;
--
        -- -----------------------------------------------------
        -- ���R�R�[�h�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_reason');
        -- -----------------------------------------------------
        -- ���R�R�[�h�f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- ���R
        prc_set_xml('D', 'reason_code', gt_main_data(i).h_reason_code);
        prc_set_xml('D', 'reason_name', gt_main_data(i).h_reason_name, 20);
        ------------------------------
        -- �i�ڂk�f�J�n�^�O
        ------------------------------
          prc_set_xml('T', 'lg_item');
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_reason_code := NVL( gt_main_data(i).h_reason_code, lc_break_null ) ;
        lv_item_code   := lc_break_init ;
        lv_cost_kbn    := lc_break_init ;
--
      END IF ;
      -- =====================================================
      -- �i�ڃu���C�N
      -- =====================================================
      -- �i�ڂ��؂�ւ�����ꍇ
      IF  (NVL(gt_main_data(i).h_item_code, lc_break_null ) <> lv_item_code ) THEN
--
        -- -----------------------------------------------------
        -- �I���^�O�o��
        -- -----------------------------------------------------
        -- ���񃌃R�[�h�̏ꍇ�͏I���^�O���o�͂��Ȃ��B
        IF  ( lv_item_code <> lc_break_init ) THEN
          lv_flg := lc_flg_n;
          -- ---------------------------
          -- ���b�g�k�f�I���^�O�o��
          -- ---------------------------
          prc_set_xml('T', '/lg_lot');
          ------------------------------
          -- �i�ڂf�I���^�O
          ------------------------------
          prc_set_xml('T', '/g_item');
        END IF ;
--
        -- -----------------------------------------------------
        -- �i�ڂf�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_item');
        -- -----------------------------------------------------
        -- �i�ڂf�^�O�o��
        -- -----------------------------------------------------
        -- �i��
        prc_set_xml('D', 'item_code', gt_main_data(i).h_item_code);
        prc_set_xml('D', 'item_name', gt_main_data(i).h_item_name, 20);
--
        -- �W���������擾
        ln_stand_unit_price := fnc_item_unit_pric_get( gt_main_data(i).item_id,
                                                       gt_main_data(i).trans_date);
        -- -----------------------------------------------------
        -- �L�[�u���C�N���̏�������
        -- -----------------------------------------------------
        -- �L�[�u���C�N�p�ϐ��ޔ�
        lv_item_code  := NVL( gt_main_data(i).h_item_code, lc_break_null ) ;
        lv_cost_kbn   := NVL( gt_main_data(i).cost_kbn, lc_break_null ) ;
        lv_locat_code := lc_break_init ;
        lv_lot_no     := lc_break_init ;
--
      END IF ;
--
      -- =====================================================
      -- ���׃f�[�^�o��
      -- =====================================================
      IF (( lv_locat_code <> lc_break_init ) AND ( lv_lot_no <> lc_break_init )) THEN
        IF   (( lr_data_dtl.locat_code <> gt_main_data(i).locat_code )    -- �q�ɃR�[�h
           OR ( lr_data_dtl.lot_no     <> gt_main_data(i).lot_no )) THEN   -- ���b�gNo
--
          -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
          IF (lv_cost_kbn = gc_cost_st ) THEN
-- 2008/11/11 v1.11 UPDATE START
--            ln_amount := ln_stand_unit_price * ln_quantity;
            ln_amount := ROUND(ln_stand_unit_price * ln_quantity);
-- 2008/11/11 v1.11 UPDATE END
          END IF;
          -- -----------------------------------------------------
          -- ���b�g�k�f�J�n�^�O�o��
          -- -----------------------------------------------------
          IF ( lv_flg <> lc_flg_y ) THEN
            prc_set_xml('T', 'lg_lot');
          END IF;
          -- -----------------------------------------------------
          -- ���b�g�f�J�n�^�O�o��
          -- -----------------------------------------------------
          prc_set_xml('T', 'g_lot');
          -- -----------------------------------------------------
          -- ���ׂf�f�[�^�^�O�o��
          -- -----------------------------------------------------
          -- �q��
          prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
          prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
          -- ������
          prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
          -- ���b�g�m��
          prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
          -- �ŗL�L��
          prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
          -- �ܖ�����
          prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
          -- ����
          prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
          -- �P��
          -- �����Ǘ��敪���u���ی����v�̏ꍇ
          IF (lv_cost_kbn = gc_cost_ac ) THEN
            -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
            IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
              prc_set_xml('D', 'unit_price',
                                    TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
            -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
            ELSE
              prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
            END IF;
          -- �����Ǘ��敪���u�W�������v�̏ꍇ
          ELSIF (lv_cost_kbn = gc_cost_st ) THEN
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          -- ����ȊO
          ELSE
            prc_set_xml('D', 'unit_price', '0');
          END IF;
          -- ���o�ɋ��z
          prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
          -- �󕥐�
          prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
          prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
          -- ���ѕ���
          prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
          prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
          -- �E�v
          prc_set_xml('D', 'description', lr_data_dtl.description, 20);
          lv_flg := lc_flg_y;
          -- -----------------------------------------------------
          -- ���b�g�f�I���^�O�o��
          -- -----------------------------------------------------
          prc_set_xml('T', '/g_lot');
          -- �v�Z���ڏ�����
          ln_quantity := 0;
          ln_amount   := 0;
        END IF;
      END IF;
      -- -----------------------------------------------------
      -- �W�v����
      -- -----------------------------------------------------
      -- ���ʉ��Z
      ln_quantity := ln_quantity + NVL(gt_main_data(i).trans_qty, 0);
      -- ���z���Z�i�����Ǘ��敪���u���ی����v�̏ꍇ�j
      IF (lv_cost_kbn = gc_cost_ac ) THEN
        -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
        IF (gt_main_data(i).lot_kbn <> gv_lot_n) THEN
          ln_amount := ln_amount
-- 2008/11/11 v1.11 UPDATE START
--                  + (NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
               + ROUND(NVL(gt_main_data(i).trans_qty,0) * NVL(gt_main_data(i).actual_unit_price,0));
-- 2008/11/11 v1.11 UPDATE END
        -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
        ELSE
          ln_amount := ln_amount
-- 2008/11/11 v1.11 UPDATE START
--                   + (NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
                   + ROUND(NVL(gt_main_data(i).trans_qty,0) * NVL(ln_stand_unit_price,0));
-- 2008/11/11 v1.11 UPDATE END
        END IF;
      END IF;
--
      -- �l��ޔ�
      lv_locat_code := NVL(gt_main_data(i).locat_code, lc_break_null );
      lv_lot_no     := NVL(gt_main_data(i).lot_no, lc_break_null );
      lr_data_dtl   := gt_main_data(i);
--
      -- �Ō�̖��ׂ��o��
      IF ( gt_main_data.LAST = i ) THEN
--
        -- ���z�Z�o�i�����Ǘ��敪���u�W�������v�̏ꍇ�j
        IF (lv_cost_kbn = gc_cost_st ) THEN
-- 2008/11/11 v1.11 UPDATE START
--          ln_amount := ln_stand_unit_price * ln_quantity;
          ln_amount := ROUND(ln_stand_unit_price * ln_quantity);
-- 2008/11/11 v1.11 UPDATE END
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�k�f�J�n�^�O�o��
        -- -----------------------------------------------------
        IF ( lv_flg <> lc_flg_y ) THEN
          prc_set_xml('T', 'lg_lot');
        END IF;
        -- -----------------------------------------------------
        -- ���b�g�f�J�n�^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', 'g_lot');
        -- -----------------------------------------------------
        -- ���ׂf�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �q��
        prc_set_xml('D', 'locat_code', lr_data_dtl.locat_code);
        prc_set_xml('D', 'locat_name', lr_data_dtl.locat_name, 20);
        -- ������
        prc_set_xml('D', 'wip_date', lr_data_dtl.wip_date);
        -- ���b�g�m��
        prc_set_xml('D', 'lot_no', lr_data_dtl.lot_no);
        -- �ŗL�L��
        prc_set_xml('D', 'original_char', lr_data_dtl.original_char);
        -- �ܖ�����
        prc_set_xml('D', 'use_by_date', lr_data_dtl.use_by_date);
        -- ����
        prc_set_xml('D', 'quantity', TO_CHAR(ROUND(ln_quantity, gn_quantity_decml)));
        -- �P��
        -- �����Ǘ��敪���u���ی����v�̏ꍇ
        IF (lv_cost_kbn = gc_cost_ac ) THEN
          -- ���b�g�Ǘ��敪���u���b�g�Ǘ��L��v�̏ꍇ
          IF (lr_data_dtl.lot_kbn <> gv_lot_n) THEN
            prc_set_xml('D', 'unit_price',
                                  TO_CHAR(NVL(lr_data_dtl.actual_unit_price,0)));
          -- ���b�g�Ǘ��敪���u���b�g�Ǘ������v�̏ꍇ
          ELSE
            prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
          END IF;
        -- �����Ǘ��敪���u�W�������v�̏ꍇ
        ELSIF (lv_cost_kbn = gc_cost_st ) THEN
          prc_set_xml('D', 'unit_price', TO_CHAR(NVL(ln_stand_unit_price,0)));
        -- ����ȊO
        ELSE
          prc_set_xml('D', 'unit_price', '0');
        END IF;
        -- ���o�ɋ��z
        prc_set_xml('D', 'in_ship_amount', TO_CHAR(ROUND(ln_amount, gn_amount_decml)));
        -- �󕥐�
        prc_set_xml('D', 'div_tocode', lr_data_dtl.div_tocode);
        prc_set_xml('D', 'div_toname', lr_data_dtl.div_toname, 20);
        -- ���ѕ���
        prc_set_xml('D', 'dept_code', lr_data_dtl.dept_code);
        prc_set_xml('D', 'dept_name', lr_data_dtl.dept_name, 20);
        -- �E�v
        prc_set_xml('D', 'description', lr_data_dtl.description, 20);
        lv_flg := lc_flg_y;
        -- -----------------------------------------------------
        -- ���b�g�f�I���^�O�o��
        -- -----------------------------------------------------
        prc_set_xml('T', '/g_lot');
      END IF;
--
    END LOOP main_data_loop ;
--
    -- =====================================================
    -- �I������
    -- =====================================================
    -- ---------------------------
    -- ���b�g�k�f�I���^�O�o��
    -- ---------------------------
    prc_set_xml('T', '/lg_lot');
    ------------------------------
    -- �i�ڂf�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_item');
    ------------------------------
    -- �i�ڂk�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_item');
    ------------------------------
    -- ���R�R�[�h�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_reason');
    ------------------------------
    -- ���R�R�[�h�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_reason');
   ------------------------------
    -- �󕥋敪�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/g_div');
   ------------------------------
    -- �󕥋敪�k�f�I���^�O
    ------------------------------
    prc_set_xml('T', '/lg_div');
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
      iv_exec_year_month    IN     VARCHAR2         -- 01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         -- 02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         -- 03 : �i�ڋ敪
     ,iv_div_type1          IN     VARCHAR2         -- 04 : �󕥋敪�P
     ,iv_div_type2          IN     VARCHAR2         -- 05 : �󕥋敪�Q
     ,iv_div_type3          IN     VARCHAR2         -- 06 : �󕥋敪�R
     ,iv_div_type4          IN     VARCHAR2         -- 07 : �󕥋敪�S
     ,iv_div_type5          IN     VARCHAR2         -- 08 : �󕥋敪�T
     ,iv_reason_code        IN     VARCHAR2         -- 09 : ���R�R�[�h
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
    lv_work_date            VARCHAR2(30); -- �ϊ��p
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
    gv_report_id               := 'XXCMN770004T' ;           -- ���[ID
    gd_exec_date               := SYSDATE ;                  -- ���{��
    -- �p�����[�^�i�[
    -- �����N��
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_exec_year_month, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.exec_year_month     := iv_exec_year_month;
    ELSE
      lr_param_rec.exec_year_month     := lv_work_date;
    END IF;
    lr_param_rec.goods_class      := iv_goods_class;       -- ���i�敪
    lr_param_rec.item_class       := iv_item_class;        -- �i�ڋ敪
    lr_param_rec.div_type1        := iv_div_type1;         -- �󕥋敪�P
    lr_param_rec.div_type2        := iv_div_type2;         -- �󕥋敪�Q
    lr_param_rec.div_type3        := iv_div_type3;         -- �󕥋敪�R
    lr_param_rec.div_type4        := iv_div_type4;         -- �󕥋敪�S
    lr_param_rec.div_type5        := iv_div_type5;         -- �󕥋敪�T
    lr_param_rec.reason_code      := iv_reason_code;       -- ���R�R�[�h
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
    IF (lv_retcode = gv_status_error) THEN
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
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <position>1</position>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_item>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_reason>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_div>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_div>' ) ;
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
     ,iv_div_type1          IN     VARCHAR2         --   04 : �󕥋敪�P
     ,iv_div_type2          IN     VARCHAR2         --   05 : �󕥋敪�Q
     ,iv_div_type3          IN     VARCHAR2         --   06 : �󕥋敪�R
     ,iv_div_type4          IN     VARCHAR2         --   07 : �󕥋敪�S
     ,iv_div_type5          IN     VARCHAR2         --   08 : �󕥋敪�T
     ,iv_reason_code        IN     VARCHAR2         --   09 : ���R�R�[�h
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
       ,iv_div_type1         => iv_div_type1         --   04 : �󕥋敪�P
       ,iv_div_type2         => iv_div_type2         --   05 : �󕥋敪�Q
       ,iv_div_type3         => iv_div_type3         --   06 : �󕥋敪�R
       ,iv_div_type4         => iv_div_type4         --   07 : �󕥋敪�S
       ,iv_div_type5         => iv_div_type5         --   08 : �󕥋敪�T
       ,iv_reason_code       => iv_reason_code       --   09 : ���R�R�[�h
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
END xxcmn770004c ;
/
