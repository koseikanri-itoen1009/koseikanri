CREATE OR REPLACE PACKAGE BODY xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_�ڋq_���ʊ֐�
 * Version                : 1.7
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check   F          �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
 *  update_hz_party            P          �p�[�e�B�}�X�^�X�V�p�֐�
 *  cust_name_kana_check       F          �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *  cust_site_check            F          �ڋq���ݒn�S�p���p�`�F�b�N
 *  cust_required_check        P          �ڋq�K�{���ڃ`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009/01/30    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009/02/26    1.1  Yutaka.Kuboshima �p�[�e�B�}�X�^�X�V�֐��ǉ�
 *  2009/03/26    1.2  Yutaka.Kuboshima �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *                                      �ڋq���ݒn�S�p���p�`�F�b�N�ǉ�
 *  2009/04/07    1.3  Yutaka.Kuboshima ��QT1_0303�̑Ή�
 *  2009/05/22    1.4  Yutaka.Kuboshima ��QT1_1089�̑Ή�
 *  2009/06/19    1.5  Yutaka.Kuboshima ��QT1_1500�̑Ή�
 *  2009/07/14    1.6  Yutaka.Kuboshima �����e�X�g��Q0000674�̑Ή�
 *  2009/07/15    1.7  Yutaka.Kuboshima �����e�X�g��Q0000648�̑Ή�
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  cv_msg_part     CONSTANT VARCHAR2(100) := ' : ';
  cv_msg_cont     CONSTANT VARCHAR2(3)   := '.';
--
  cv_pkg_name     CONSTANT VARCHAR2(100) := 'XXCMM_003COMMON_PKG';              -- �p�b�P�[�W��
  cv_cnst_period  CONSTANT VARCHAR2(1)   := '.';                                -- �s���I�h
--
  cv_success      CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_error        CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  cv_success_api  CONSTANT VARCHAR2(1)   := 'S';                                -- API�������ԋp�X�e�[�^�X
  cv_user_entered CONSTANT VARCHAR2(12)  := 'USER_ENTERED';                     --�p�[�e�B�}�X�^�X�V�`�o�h�R���e���c�\�[�X�^�C�v
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
--
  /**********************************************************************************
   * Function  Name   : cust_status_update_allow
   * Description      : �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
   ***********************************************************************************/
  --���^�[���R�[�hnormal�̂Ƃ��X�V�\�B���^�[���R�[�herror�̂Ƃ��X�V�s�B
  FUNCTION cust_status_update_allow(iv_cust_class        IN VARCHAR2  -- �ڋq�敪
                                   ,iv_cust_status       IN VARCHAR2  -- �ڋq�X�e�[�^�X�i�ύX�O�j
                                   ,iv_cust_will_status  IN VARCHAR2) -- �ڋq�X�e�[�^�X�i�ύX��j
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_kyoten         CONSTANT VARCHAR2(1) := '1';
    cv_out_cust       CONSTANT VARCHAR2(2) := '99';
    cv_rectif_credit  CONSTANT VARCHAR2(2) := '80';
    cv_stop_approved  CONSTANT VARCHAR2(2) := '90';
    cv_mc             CONSTANT VARCHAR2(2) := '20';
    cv_sp_approved    CONSTANT VARCHAR2(2) := '25';
    cv_approved       CONSTANT VARCHAR2(2) := '30';
    cv_cust           CONSTANT VARCHAR2(2) := '40';
    cv_rested         CONSTANT VARCHAR2(2) := '50';
-- 2009/04/07 Ver1.3 add start by Yutaka.Kuboshima
    cv_mc_candidates  CONSTANT VARCHAR2(2) := '10';
-- 2009/04/07 Ver1.3 add end by Yutaka.Kuboshima
    cv_customer       CONSTANT VARCHAR2(2) := '10';
    cv_su_customer    CONSTANT VARCHAR2(2) := '12';
    cv_trust_corp     CONSTANT VARCHAR2(2) := '13';
    cv_ar_manage      CONSTANT VARCHAR2(2) := '14';
    cv_root           CONSTANT VARCHAR2(2) := '15';
    cv_wholesale      CONSTANT VARCHAR2(2) := '16';
    cv_planning       CONSTANT VARCHAR2(2) := '17';
    cv_edi            CONSTANT VARCHAR2(2) := '18';
    cv_hyakka         CONSTANT VARCHAR2(2) := '19';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
  --
  BEGIN
    IF (iv_cust_status = iv_cust_will_status) THEN
      RETURN cv_success;
    ELSIF (iv_cust_class = cv_kyoten) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_customer) THEN
      IF (iv_cust_status = cv_mc) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_sp_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND ((iv_cust_will_status = cv_rested) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
        RETURN cv_success;
-- 2009/07/14 Ver1.6 modify start by Yutaka.Kuboshima
--      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_mc) OR (iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
-- 2009/07/14 Ver1.6 modify end by Yutaka.Kuboshima
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
-- 2009/04/07 Ver1.3 add start by Yutaka.Kuboshima
      ELSIF (iv_cust_status = cv_mc_candidates) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
-- 2009/04/07 Ver1.3 add end by Yutaka.Kuboshima
      END IF;
    ELSIF (iv_cust_class = cv_su_customer) THEN
      IF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_trust_corp) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_ar_manage) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF ((iv_cust_class = cv_root) OR (iv_cust_class = cv_wholesale) OR (iv_cust_class = cv_planning) OR (iv_cust_class = cv_edi) OR (iv_cust_class = cv_hyakka)) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    END IF;
    RETURN cv_error;
  END cust_status_update_allow;
  /**********************************************************************************
   * Procedure  Name  : update_hz_party
   * Description      : �p�[�e�B�}�X�^�X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_hz_party(in_party_id    IN  NUMBER,    -- �p�[�e�BID
                            iv_cust_status IN  VARCHAR2,  -- �ڋq�X�e�[�^�X
                            ov_errbuf      OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ov_retcode     OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
                            ov_errmsg      OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ���[�J���萔
    cv_prg_name                       CONSTANT VARCHAR2(100) := 'update_hz_party'; -- �v���O������
    cv_init_list_api                  CONSTANT VARCHAR2(1)   := 'T';               -- API�N���������X�g�ݒ�l
    -- ���[�J���ϐ�
    lv_return_status                  VARCHAR2(5000);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(5000);
    lv_retcode                        VARCHAR2(1);
    lv_errmsg                         VARCHAR2(5000);
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       hz_party_v2pub.party_rec_type;
    p_organization_rec                hz_party_v2pub.organization_rec_type;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
    -- �J�[�\���錾
    -- �p�[�e�B�}�X�^�I�u�W�F�N�g�i���o�[�擾�J�[�\��
    CURSOR get_party_object_number_cur
    IS
      SELECT hp.object_version_number object_version_number
      FROM hz_parties hp
      WHERE hp.party_id = in_party_id;
    -- �p�[�e�B�}�X�^�I�u�W�F�N�g�i���o�[�擾���R�[�h�^
    get_party_object_number_rec get_party_object_number_cur%ROWTYPE;
  BEGIN
    --�p�[�e�BID�ݒ�
    ln_party_id := in_party_id;
    -- �I�u�W�F�N�g�i���o�[�擾
    OPEN get_party_object_number_cur;
    FETCH get_party_object_number_cur INTO get_party_object_number_rec;
    CLOSE get_party_object_number_cur;
    -- �R���e���g�\�[�X�^�C�v�ݒ�
    lv_content_source_type := cv_user_entered;
    --�g�D���擾API
    hz_party_v2pub.get_organization_rec(cv_init_list_api,
                                        ln_party_id,
                                        lv_content_source_type,
                                        p_organization_rec,
                                        lv_return_status,
                                        ln_msg_count,
                                        lv_msg_data);
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --�p�[�e�B���擾API
    hz_party_v2pub.get_party_rec(cv_init_list_api,
                                 ln_party_id,
                                 p_party_rec,
                                 lv_return_status,
                                 ln_msg_count,
                                 lv_msg_data);
    --�p�[�e�B���X�V�l�ݒ�
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --�ڋq�X�e�[�^�X�ݒ�
    p_organization_rec.duns_number_c := iv_cust_status;
    --�I�u�W�F�N�g�i���o�[�ݒ�
    ln_party_object_version_number   := get_party_object_number_rec.object_version_number;
    --�p�[�e�B���ݒ�
    p_organization_rec.party_rec     := p_party_rec;
    --�p�[�e�B�}�X�^�X�VAPI�Ăяo��
    hz_party_v2pub.update_organization(cv_init_list_api,
                                       p_organization_rec,
                                       ln_party_object_version_number,
                                       ln_profile_id,
                                       lv_return_status,
                                       ln_msg_count,
                                       lv_msg_data);
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    ov_retcode := cv_success;
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_msg_data;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont|| cv_prg_name || cv_msg_part || lv_msg_data, 1, 5000);
      ov_retcode := cv_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_cnst_period || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000), TRUE);
  END update_hz_party;
  /**********************************************************************************
   * Function  Name   : cust_name_kana_check
   * Description      : �ڋq���́E�ڋq���̃J�i�`�F�b�N
   ***********************************************************************************/
  --�ڋq���́E�ڋq���̃J�i�`�F�b�N�B���^�[���R�[�hnormal�̂Ƃ�����B���^�[���R�[�herror�̂Ƃ��G���[�B
  FUNCTION cust_name_kana_check(iv_cust_name_mir           IN VARCHAR2   -- �ڋq����
                               ,iv_cust_name_phonetic_mir  IN VARCHAR2)  -- �ڋq���̃J�i
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
  --
  BEGIN
    IF     NVL(xxccp_common_pkg.chk_double_byte(iv_cust_name_mir),TRUE)
      AND  NVL(xxccp_common_pkg.chk_single_byte(iv_cust_name_phonetic_mir),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_name_kana_check;
--
  /**********************************************************************************
   * Function  Name   : cust_site_check
   * Description      : �ڋq���ݒn�S�p���p�`�F�b�N
   ***********************************************************************************/
  --�ڋq���ݒn�S�p���p�`�F�b�N�B���^�[���R�[�hnormal�̂Ƃ�����B���^�[���R�[�herror�̂Ƃ��G���[�B
  FUNCTION cust_site_check(iv_cust_site IN VARCHAR2)  -- �ڋq���ݒn������
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_dot        CONSTANT VARCHAR2(1) := '.';
    cv_escape_dot CONSTANT VARCHAR2(2) := '\.';
  --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_cust_site VARCHAR2(3000) := NULL;
  --
  BEGIN
    --�G�X�P�[�v�V�[�P���X��\.�𕶎��񂩂珜��
    lv_cust_site := REPLACE(iv_cust_site, cv_escape_dot);
    IF   (xxccp_common_pkg.chk_number(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                              ,cv_dot
                                                                              ,1))
      AND LENGTHB(xxccp_common_pkg.char_delim_partition( lv_cust_site
                                                        ,cv_dot
                                                        ,1)) = 7)
      AND xxccp_common_pkg.chk_tel_format(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                 ,cv_dot
                                                                                 ,7))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,2))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,3))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,4))
      AND nvl(xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                      ,cv_dot
                                                                                      ,5)),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_site_check;
-- 2009/05/22 Ver1.4 add start by Yutaka.Kuboshima
  /**********************************************************************************
   * Procedure  Name  : cust_required_check
   * Description      : �ڋq�K�{���ڃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE cust_required_check(
-- 2009/06/19 Ver1.5 modify start by Yutaka.Kuboshima
--                                iv_customer_number  IN  VARCHAR2,  -- �ڋq�ԍ�
                                in_customer_id      IN  NUMBER,    -- �ڋqID
-- 2009/06/19 Ver1.5 modify end by Yutaka.Kuboshima
                                iv_cust_status      IN  VARCHAR2,  -- �ڋq�X�e�[�^�X�i�ύX�O�j
                                iv_cust_will_status IN  VARCHAR2,  -- �ڋq�X�e�[�^�X�i�ύX��j
                                ov_retcode          OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
                                ov_errmsg           OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(50) := 'cust_required_check';  -- �v���O������
    cv_cnst_msg_kbn         CONSTANT VARCHAR2(5)  := 'XXCMM';                -- �A�h�I���F���ʁE�}�X�^
    -- ���b�Z�[�W
    cv_msg_xxcmm_00001      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';     -- �Ώۃf�[�^�����G���[
    cv_msg_xxcmm_00347      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00347';     -- �g�p�ړI���݃`�F�b�N�G���[
    cv_msg_xxcmm_00348      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00348';     -- ���ږ��ݒ�G���[
    cv_msg_xxcmm_00349      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00349';     -- �m�F���b�Z�[�W
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_msg_xxcmm_00350      CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00350';     -- �x�����@���o�^���b�Z�[�W
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
    --
    -- �g�[�N��
    cv_tkn_site_use         CONSTANT VARCHAR2(16) := 'SITE_USE';             -- �g�p�ړI��
    cv_tkn_item             CONSTANT VARCHAR2(16) := 'ITEM';                 -- ���ږ�
    --
    -- �g�[�N���l
    cv_token_cust_number    CONSTANT VARCHAR2(50) := '[�ڋq�ԍ�]';           -- �g�[�N���l(�ڋq�ԍ�)
    cv_token_cust_kbn       CONSTANT VARCHAR2(50) := '[�ڋq�敪]';           -- �g�[�N���l(�ڋq�敪)
    cv_token_cust_name      CONSTANT VARCHAR2(50) := '[�ڋq����]';           -- �g�[�N���l(�ڋq����)
    cv_token_postal_code    CONSTANT VARCHAR2(50) := '[�X�֔ԍ�]';           -- �g�[�N���l(�X�֔ԍ�)
    cv_token_state          CONSTANT VARCHAR2(50) := '[�s���{��]';           -- �g�[�N���l(�s���{��)
    cv_token_city           CONSTANT VARCHAR2(50) := '[�s�E��]';             -- �g�[�N���l(�s�E��)
    cv_token_address1       CONSTANT VARCHAR2(50) := '[�Z���P]';             -- �g�[�N���l(�Z���P)
    cv_token_address3       CONSTANT VARCHAR2(50) := '[�n��R�[�h]';         -- �g�[�N���l(�n��R�[�h)
    cv_token_phonetic       CONSTANT VARCHAR2(50) := '[�d�b�ԍ�]';           -- �g�[�N���l(�d�b�ԍ�)
    cv_token_old_code       CONSTANT VARCHAR2(50) := '[���{���R�[�h]';       -- �g�[�N���l(���{���R�[�h)
    cv_token_new_code       CONSTANT VARCHAR2(50) := '[�V�{���R�[�h]';       -- �g�[�N���l(�V�{���R�[�h)
    cv_token_apply_date     CONSTANT VARCHAR2(50) := '[�K�p�J�n��]';         -- �g�[�N���l(�K�p�J�n��)
    cv_token_actual_div     CONSTANT VARCHAR2(50) := '[���_���їL���敪]';   -- �g�[�N���l(���_���їL���敪)
    cv_token_ship_div       CONSTANT VARCHAR2(50) := '[�o�׊Ǘ����敪]';     -- �g�[�N���l(�o�׊Ǘ����敪)
    cv_token_change_div     CONSTANT VARCHAR2(50) := '[�q�֑Ώۉۋ敪]';   -- �g�[�N���l(�q�֑Ώۉۋ敪)
    cv_token_user_div       CONSTANT VARCHAR2(50) := '[���p�ҋ敪]';         -- �g�[�N���l(���p�ҋ敪)
    cv_token_bill_to        CONSTANT VARCHAR2(50) := '[������]';             -- �g�[�N���l(������)
    cv_token_ship_to        CONSTANT VARCHAR2(50) := '[�o�א�]';             -- �g�[�N���l(�o�א�)
    cv_token_other_to       CONSTANT VARCHAR2(50) := '[���̑�]';             -- �g�[�N���l(���̑�)
    cv_token_bill_to_use_id CONSTANT VARCHAR2(50) := '[�����掖�Ə�]';       -- �g�[�N���l(�����掖�Ə�)
    cv_token_invoice_div    CONSTANT VARCHAR2(50) := '[���������s�敪]';     -- �g�[�N���l(���������s�敪)
    cv_token_payment_id     CONSTANT VARCHAR2(50) := '[�x������]';           -- �g�[�N���l(�x������)
    cv_token_tax_rule       CONSTANT VARCHAR2(50) := '[�ŋ��[������]';       -- �g�[�N���l(�ŋ��[������)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_token_site_use       CONSTANT VARCHAR2(50) := '�g�p�ړI';             -- �g�[�N���l(�g�p�ړI)
    cv_token_no             CONSTANT VARCHAR2(50) := '��';                   -- �g�[�N���l(��)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
    -- �ڋq�敪
    cv_cust_kyoten_kbn      CONSTANT VARCHAR2(2)  := '1';                    -- ���_
    cv_cust_kokyaku_kbn     CONSTANT VARCHAR2(2)  := '10';                   -- �ڋq
    cv_cust_uesama_kbn      CONSTANT VARCHAR2(2)  := '12';                   -- ��l�ڋq
    cv_cust_houjin_kbn      CONSTANT VARCHAR2(2)  := '13';                   -- �@�l�ڋq
    cv_cust_urikake_kbn     CONSTANT VARCHAR2(2)  := '14';                   -- ���|�Ǘ���
    cv_cust_junkai_kbn      CONSTANT VARCHAR2(2)  := '15';                   -- ����
    cv_cust_hanbai_kbn      CONSTANT VARCHAR2(2)  := '16';                   -- �̔���
    cv_cust_keikaku_kbn     CONSTANT VARCHAR2(2)  := '17';                   -- �v�旧�ėp
    cv_cust_edichain_kbn    CONSTANT VARCHAR2(2)  := '18';                   -- EDI�`�F�[��
    cv_cust_hyakkaten_kbn   CONSTANT VARCHAR2(2)  := '19';                   -- �S�ݓX�`��
    -- �ڋq�X�e�[�^�X
    cv_cust_mckouho_sts     CONSTANT VARCHAR2(2)  := '10';                   -- MC���
    cv_cust_mc_sts          CONSTANT VARCHAR2(2)  := '20';                   -- MC
    cv_cust_spkessai_sts    CONSTANT VARCHAR2(2)  := '25';                   -- SP���ٍ�
    cv_cust_shounin_sts     CONSTANT VARCHAR2(2)  := '30';                   -- ���F��
    cv_cust_kokyaku_sts     CONSTANT VARCHAR2(2)  := '40';                   -- �ڋq
    cv_cust_kyusi_sts       CONSTANT VARCHAR2(2)  := '50';                   -- �x�~
    cv_cust_kousei_sts      CONSTANT VARCHAR2(2)  := '80';                   -- �X����
    cv_cust_tyusi_sts       CONSTANT VARCHAR2(2)  := '90';                   -- ���~���ٍ�
    cv_cust_taishougai_sts  CONSTANT VARCHAR2(2)  := '99';                   -- �ΏۊO
    -- �g�p�ړI�R�[�h
    cv_site_use_bill_to     CONSTANT VARCHAR2(10) := 'BILL_TO';              -- �g�p�ړI�R�[�h(������)
    cv_site_use_ship_to     CONSTANT VARCHAR2(10) := 'SHIP_TO';              -- �g�p�ړI�R�[�h(�o�א�)
    cv_site_use_other_to    CONSTANT VARCHAR2(10) := 'OTHER_TO';             -- �g�p�ړI�R�[�h(���̑�)
    -- ���̑�
    cv_a_flag               CONSTANT VARCHAR2(1)  := 'A';                    -- �L���t���O(A)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    cv_y_flag               CONSTANT VARCHAR2(1)  := 'Y';                    -- �L���t���O(Y)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errmsg               VARCHAR2(8000);
    lv_errmsg_00347         VARCHAR2(2000);
    lv_errmsg_00348         VARCHAR2(2000);
    lv_errmsg_00349         VARCHAR2(2000);
    lv_item_token           VARCHAR2(4000);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    lv_item_token_bill      VARCHAR2(200);   -- �g�p�ړI[������]��p�g�[�N��
    lv_item_token_ship      VARCHAR2(200);   -- �g�p�ړI[�o�א�]��p�g�[�N��
    lv_errmsg_00348_bill    VARCHAR2(2000);  -- �g�p�ړI[������]��p���b�Z�[�W
    lv_errmsg_00348_ship    VARCHAR2(2000);  -- �g�p�ړI[�o�א�]��p���b�Z�[�W
    lv_errmsg_00350         VARCHAR2(2000);  -- �x�����@���o�^�G���[���b�Z�[�W
    lv_receipt_err          VARCHAR2(1);     -- �x�����@�`�F�b�N����
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
    lv_site_use_token       VARCHAR2(200);
    lv_retcode              VARCHAR2(1);
--
    -- ===============================
    -- ���[�J���J�[�\��
    -- ===============================
    -- �ڋq�K�{���ڃ`�F�b�N�p�J�[�\��
    CURSOR cust_required_check_cur
    IS
      SELECT hca.account_number          account_number          -- �ڋq�ԍ�
            ,hca.customer_class_code     customer_class_code     -- �ڋq�敪
            ,hca.attribute1              old_base_code           -- ���{���R�[�h
            ,hca.attribute2              new_base_code           -- �V�{���R�[�h
            ,hca.attribute3              apply_start_date        -- �K�p�J�n��
            ,hca.attribute4              base_actual_exists_div  -- ���_���їL���敪
            ,hca.attribute5              ship_management_div     -- �o�׊Ǘ����敪
            ,hca.attribute6              change_bay_target_div   -- �q�֑Ώۉۋ敪
            ,hca.attribute8              user_div                -- ���p�ҋ敪
            ,hp.party_name               party_name              -- �ڋq����
            ,cust.postal_code            postal_code             -- �X�֔ԍ�
            ,cust.state                  state                   -- �s���{��
            ,cust.city                   city                    -- �s�E��
            ,cust.address1               address1                -- �Z���P
            ,cust.address3               address3                -- �n��R�[�h
            ,cust.address_lines_phonetic address_lines_phonetic  -- �d�b�ԍ�
            ,cust.site_use_code          site_use_code           -- �g�p�ړI
            ,cust.bill_to_site_use_id    bill_to_site_use_id     -- �����掖�Ə�
            ,cust.invoice_issue_div      invoice_issue_div       -- ���������s�敪
            ,cust.payment_term_id        payment_term_id         -- �x������
            ,cust.tax_rounding_rule      tax_rounding_rule       -- �ŋ��[������
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
            ,cust.primary_flag           primary_flag            -- �x�����@��t���O
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      FROM   hz_cust_accounts   hca
            ,hz_parties         hp
            ,(SELECT hca2.cust_account_id       cust_account_id
                    ,hl2.postal_code            postal_code
                    ,hl2.state                  state
                    ,hl2.city                   city
                    ,hl2.address1               address1
                    ,hl2.address3               address3
                    ,hl2.address_lines_phonetic address_lines_phonetic
                    ,hcsuv.site_use_code        site_use_code
                    ,hcsuv.bill_to_site_use_id  bill_to_site_use_id
                    ,hcsuv.invoice_issue_div    invoice_issue_div
                    ,hcsuv.payment_term_id      payment_term_id
                    ,hcsuv.tax_rounding_rule    tax_rounding_rule
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                    ,rcrmv.primary_flag         primary_flag
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
              FROM   hz_cust_accounts   hca2
                    ,hz_parties         hp2
                    ,hz_party_sites     hps2
                    ,hz_locations       hl2
                    ,(SELECT hca3.cust_account_id       cust_account_id
                            ,hcsu3.site_use_code        site_use_code
                            ,hcsu3.bill_to_site_use_id  bill_to_site_use_id
                            ,hcsu3.attribute1           invoice_issue_div
                            ,hcsu3.payment_term_id      payment_term_id
                            ,hcsu3.tax_rounding_rule    tax_rounding_rule
                      FROM   hz_cust_accounts   hca3
                            ,hz_parties         hp3
                            ,hz_party_sites     hps3
                            ,hz_locations       hl3
                            ,hz_cust_acct_sites hcas3
                            ,hz_cust_site_uses  hcsu3
                      WHERE  hca3.party_id           = hp3.party_id
                        AND  hp3.party_id            = hps3.party_id
                        AND  hps3.location_id        = hl3.location_id
                        AND  hps3.party_site_id      = hcas3.party_site_id
                        AND  hcas3.cust_acct_site_id = hcsu3.cust_acct_site_id
                        AND  hcsu3.status            = cv_a_flag
                        AND ( ( hca3.customer_class_code = cv_cust_kyoten_kbn
                            AND hcsu3.site_use_code = cv_site_use_other_to)
                          OR  ( hca3.customer_class_code IN (cv_cust_kokyaku_kbn, cv_cust_uesama_kbn)
                            AND hcsu3.site_use_code IN (cv_site_use_bill_to, cv_site_use_ship_to))
                          OR  ( hca3.customer_class_code = cv_cust_urikake_kbn
                            AND hcsu3.site_use_code = cv_site_use_bill_to)
                          OR  ( hca3.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn)
                            AND hcsu3.site_use_code = cv_site_use_other_to)
                            )
                        AND  hl3.location_id         = (SELECT MIN(hps31.location_id)
                                                        FROM   hz_cust_acct_sites hcas31,
                                                               hz_party_sites     hps31
                                                        WHERE  hcas31.cust_account_id = hca3.cust_account_id
                                                        AND    hcas31.party_site_id   = hps31.party_site_id
                                                        AND    hps31.status           = cv_a_flag)
                     ) hcsuv
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                    ,(SELECT hca.cust_account_id customer_id
                            ,rcrm.primary_flag   primary_flag
                      FROM   hz_cust_accounts        hca
                            ,ra_cust_receipt_methods rcrm
                      WHERE  hca.cust_account_id = rcrm.customer_id
                        AND  rcrm.cust_receipt_method_id = (SELECT rcrm2.cust_receipt_method_id
                                                            FROM   hz_cust_accounts hca2
                                                                  ,hz_cust_acct_sites hcas2
                                                                  ,ra_cust_receipt_methods rcrm2
                                                            WHERE  hca2.cust_account_id = rcrm2.customer_id
                                                              AND  hca2.cust_account_id = hcas2.cust_account_id
                                                              AND  hca.cust_account_id  = hca2.cust_account_id
                                                              AND  rcrm.primary_flag    = cv_y_flag
                                                              AND  ROWNUM = 1)
                     ) rcrmv
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
              WHERE  hca2.party_id           = hp2.party_id(+)
                AND  hp2.party_id            = hps2.party_id(+)
                AND  hps2.location_id        = hl2.location_id(+)
                AND  hca2.cust_account_id    = hcsuv.cust_account_id(+)
                AND  hl2.location_id         = (SELECT MIN(hps21.location_id)
                                                FROM   hz_cust_acct_sites hcas21,
                                                       hz_party_sites     hps21
                                                WHERE  hcas21.cust_account_id = hca2.cust_account_id
                                                AND    hcas21.party_site_id   = hps21.party_site_id
                                                AND    hps21.status           = cv_a_flag)
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
                AND  hca2.cust_account_id    = rcrmv.customer_id(+)
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
             ) cust
      WHERE  hca.party_id        = hp.party_id(+)
        AND  hca.cust_account_id = cust.cust_account_id(+)
-- 2009/06/19 Ver1.5 modify start by Yutaka.Kuboshima
--        AND  hca.account_number  = iv_customer_number
        AND  hca.cust_account_id = in_customer_id
-- 2009/06/19 Ver1.5 modify end by Yutaka.Kuboshima
      ORDER BY cust.site_use_code;
    -- �ڋq�K�{���ڃ`�F�b�N�p�J�[�\���^���R�[�h
    cust_required_check_rec cust_required_check_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    no_data_found_expt EXCEPTION;
--
  BEGIN
--
    -- ��������
    lv_errmsg  := NULL;
    lv_retcode := cv_success;
    -- �Ώۃf�[�^�擾
    OPEN cust_required_check_cur;
    FETCH cust_required_check_cur INTO cust_required_check_rec;
    -- �Ώۃf�[�^�����݂��邩
    IF (cust_required_check_cur%NOTFOUND) THEN
      RAISE no_data_found_expt;
    END IF;
    -- �`�F�b�N�N������
    IF ( (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_mckouho_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_mc_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status = cv_cust_spkessai_sts
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kyoten_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_kokyaku_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_uesama_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_shounin_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_houjin_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_urikake_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_junkai_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_hanbai_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_keikaku_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_edichain_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
      OR (  cust_required_check_rec.customer_class_code = cv_cust_hyakkaten_kbn
        AND iv_cust_status IS NULL
        AND iv_cust_will_status =cv_cust_taishougai_sts)
       )
    THEN
      -- �ڋq�ԍ�NULL�`�F�b�N
      IF (cust_required_check_rec.account_number IS NULL) THEN
        lv_item_token := cv_token_cust_number;
      END IF;
      -- �ڋq�敪NULL�`�F�b�N
      IF (cust_required_check_rec.customer_class_code IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_cust_kbn;
      END IF;
      -- �ڋq����NULL�`�F�b�N
      IF (cust_required_check_rec.party_name IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_cust_name;
      END IF;
      -- �X�֔ԍ�NULL�`�F�b�N
      IF (cust_required_check_rec.postal_code IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_postal_code;
      END IF;
      -- �s���{��NULL�`�F�b�N
      IF (cust_required_check_rec.state IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_state;
      END IF;
      -- �s�E��NULL�`�F�b�N
      IF (cust_required_check_rec.city IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_city;
      END IF;
      -- �Z���PNULL�`�F�b�N
      IF (cust_required_check_rec.address1 IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_address1;
      END IF;
      -- �n��R�[�hNULL�`�F�b�N
      IF (cust_required_check_rec.address3 IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_address3;
      END IF;
      -- �d�b�ԍ�NULL�`�F�b�N
      IF (cust_required_check_rec.address_lines_phonetic IS NULL) THEN
        lv_item_token := lv_item_token || cv_token_phonetic;
      END IF;
      -- �ڋq�敪��'1'(���_)�̏ꍇ
      IF (cust_required_check_rec.customer_class_code = cv_cust_kyoten_kbn) THEN
        -- ���{���R�[�hNULL�`�F�b�N
        IF (cust_required_check_rec.old_base_code IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_old_code;
        END IF;
        -- �V�{���R�[�hNULL�`�F�b�N
        IF (cust_required_check_rec.new_base_code IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_new_code;
        END IF;
        -- �K�p�J�n��NULL�`�F�b�N
        IF (cust_required_check_rec.apply_start_date IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_apply_date;
        END IF;
        -- ���_���їL���敪NULL�`�F�b�N
        IF (cust_required_check_rec.base_actual_exists_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_actual_div;
        END IF;
        -- �o�׊Ǘ����敪NULL�`�F�b�N
        IF (cust_required_check_rec.ship_management_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_ship_div;
        END IF;
        -- �q�֑Ώۉۋ敪NULL�`�F�b�N
        IF (cust_required_check_rec.change_bay_target_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_change_div;
        END IF;
        -- ���p�ҋ敪NULL�`�F�b�N
        IF (cust_required_check_rec.user_div IS NULL) THEN
          lv_item_token := lv_item_token || cv_token_user_div;
        END IF;
        -- �g�p�ړI���݃`�F�b�N
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_other_to;
        END IF;
      -- �ڋq�敪��'10'(�ڋq),'12'(��l�ڋq)�̏ꍇ
      ELSIF (cust_required_check_rec.customer_class_code IN (cv_cust_kokyaku_kbn, cv_cust_uesama_kbn)) THEN
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        -- �x�����@���݃`�F�b�N
        IF (cust_required_check_rec.primary_flag IS NULL) THEN
          lv_receipt_err := cv_error;
        END IF;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
        -- �g�p�ړI(������)���݃`�F�b�N
        -- �g�p�ړI��NULL(������A�o�א拤�ɖ��ݒ�)�̏ꍇ
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to || cv_token_ship_to;
        -- �g�p�ړI(�o�א�)�̏ꍇ
        ELSIF (cust_required_check_rec.site_use_code = cv_site_use_ship_to) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to;
          -- �����掖�Ə�NULL�`�F�b�N
          IF (cust_required_check_rec.bill_to_site_use_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_bill_to_use_id;
            lv_item_token_ship := lv_item_token_ship || cv_token_bill_to_use_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
        -- �g�p�ړI(������)�̏ꍇ
        ELSIF (cust_required_check_rec.site_use_code = cv_site_use_bill_to) THEN
          -- ���������s�敪NULL�`�F�b�N
          IF (cust_required_check_rec.invoice_issue_div IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_invoice_div;
            lv_item_token_bill := lv_item_token_bill || cv_token_invoice_div;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- �x������NULL�`�F�b�N
          IF (cust_required_check_rec.payment_term_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_payment_id;
            lv_item_token_bill := lv_item_token_bill || cv_token_payment_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- �ŋ��[������NULL�`�F�b�N
          IF (cust_required_check_rec.tax_rounding_rule IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_tax_rule;
            lv_item_token_bill := lv_item_token_bill || cv_token_tax_rule;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- �o�א惌�R�[�h�̎擾
          FETCH cust_required_check_cur INTO cust_required_check_rec;
          -- �Ώۃf�[�^�����݂��邩
          -- ���݂��Ȃ��ꍇ�A�o�א惌�R�[�h���ݒ�
          IF (cust_required_check_cur%NOTFOUND) THEN
            lv_site_use_token := lv_site_use_token || cv_token_ship_to;
          ELSE
            -- �����掖�Ə�NULL�`�F�b�N
            IF (cust_required_check_rec.bill_to_site_use_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--              lv_item_token := lv_item_token || cv_token_bill_to_use_id;
              lv_item_token_ship := lv_item_token_ship || cv_token_bill_to_use_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
            END IF;
          END IF;
        END IF;
      -- �ڋq�敪��'14'(���|�Ǘ���)�̏ꍇ
      ELSIF (cust_required_check_rec.customer_class_code = cv_cust_urikake_kbn) THEN
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        -- �x�����@���݃`�F�b�N
        IF (cust_required_check_rec.primary_flag IS NULL) THEN
          lv_receipt_err := cv_error;
        END IF;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
        -- �g�p�ړI(������)���݃`�F�b�N
        -- �g�p�ړI��NULL(�����斢�ݒ�)�̏ꍇ
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_bill_to;
        ELSE
          -- ���������s�敪NULL�`�F�b�N
          IF (cust_required_check_rec.invoice_issue_div IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_invoice_div;
            lv_item_token_bill := lv_item_token_bill || cv_token_invoice_div;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- �x������NULL�`�F�b�N
          IF (cust_required_check_rec.payment_term_id IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_payment_id;
            lv_item_token_bill := lv_item_token_bill || cv_token_payment_id;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
          -- �ŋ��[������NULL�`�F�b�N
          IF (cust_required_check_rec.tax_rounding_rule IS NULL) THEN
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--            lv_item_token := lv_item_token || cv_token_tax_rule;
            lv_item_token_bill := lv_item_token_bill || cv_token_tax_rule;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
          END IF;
        END IF;
      -- �ڋq�敪��'13'(�@�l�ڋq),'15'(����),'16'(�̔���),'17'(�v�旧�ėp),'18'(EDI�`�F�[��),'19'(�S�ݓX�`��)�̏ꍇ
      ELSIF (cust_required_check_rec.customer_class_code IN (cv_cust_houjin_kbn, cv_cust_junkai_kbn, cv_cust_hanbai_kbn, cv_cust_keikaku_kbn, cv_cust_edichain_kbn, cv_cust_hyakkaten_kbn)) THEN
        -- �g�p�ړI���݃`�F�b�N
        IF (cust_required_check_rec.site_use_code IS NULL) THEN
          lv_site_use_token := lv_site_use_token || cv_token_other_to;
        END IF;
      END IF;
      -- �G���[���b�Z�[�W����
      -- ����NULL�`�F�b�N�G���[�̏ꍇ
      IF (lv_item_token IS NOT NULL) THEN
        lv_errmsg_00348 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00348,
                                                    cv_tkn_item,
                                                    lv_item_token) || CHR(10);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        lv_retcode := cv_error;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      END IF;
      -- �g�p�ړI���݃`�F�b�N�G���[�̏ꍇ
      IF (lv_site_use_token IS NOT NULL) THEN
        lv_errmsg_00347 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00347,
                                                    cv_tkn_site_use,
                                                    lv_site_use_token) || CHR(10);
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
        lv_retcode := cv_error;
-- 2009/07/15 Ver1.7 add end by Yutaka.Kuboshima
      END IF;
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
      -- �g�p�ړI[������]����NULL�`�F�b�N�G���[�̏ꍇ
      IF (lv_item_token_bill IS NOT NULL) THEN
        lv_errmsg_00348_bill := cv_token_site_use || cv_token_bill_to || cv_token_no ||
                                xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                         cv_msg_xxcmm_00348,
                                                         cv_tkn_item,
                                                         lv_item_token_bill) || CHR(10);
        lv_retcode := cv_error;
      END IF;
      -- �g�p�ړI[�o�א�]����NULL�`�F�b�N�G���[�̏ꍇ
      IF (lv_item_token_ship IS NOT NULL) THEN
        lv_errmsg_00348_ship := cv_token_site_use || cv_token_ship_to || cv_token_no ||
                                xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                         cv_msg_xxcmm_00348,
                                                         cv_tkn_item,
                                                         lv_item_token_ship) || CHR(10);
        lv_retcode := cv_error;
      END IF;
      -- �x�����@���o�^�`�F�b�N�G���[�̏ꍇ
      IF (lv_receipt_err = cv_error) THEN
        lv_errmsg_00350 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00350) || CHR(10);
        lv_retcode := cv_error;
      END IF;
-- 2009/07/15 Ver1.7 add start by Yutaka.Kuboshima
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--      IF (lv_errmsg_00347 IS NOT NULL OR lv_errmsg_00348 IS NOT NULL) THEN
      -- ���^�[���R�[�h���x���̏ꍇ
      IF (lv_retcode = cv_error) THEN
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
        lv_errmsg_00349 := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                                    cv_msg_xxcmm_00349);
-- 2009/07/15 Ver1.7 modify start by Yutaka.Kuboshima
--        lv_errmsg  := lv_errmsg_00347 || lv_errmsg_00348 || lv_errmsg_00349;
        lv_errmsg  := lv_errmsg_00347 || lv_errmsg_00348 || lv_errmsg_00348_bill ||
                      lv_errmsg_00348_ship || lv_errmsg_00350 || lv_errmsg_00349;
-- 2009/07/15 Ver1.7 modify end by Yutaka.Kuboshima
      END IF;
    END IF;
    -- OUT�p�����[�^�Z�b�g
    ov_errmsg  := lv_errmsg;
    ov_retcode := lv_retcode;
  EXCEPTION
    -- *** �Ώۃf�[�^���� ***
    WHEN no_data_found_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(cv_cnst_msg_kbn,
                                             cv_msg_xxcmm_00001);
      ov_retcode := cv_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_cnst_period || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000), TRUE);
  END cust_required_check;
-- 2009/05/22 Ver1.4 add end by Yutaka.Kuboshima
END xxcmm_003common_pkg;
/
