/*============================================================================
* �t�@�C���� : XxcsoSpDecisionPropertyUtils
* �T�v����   : SP�ꌈ�\�������v���p�e�B�ݒ胆�[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS����_     �V�K�쐬
* 2009-04-20 1.1  SCS�������l   [ST��QT1_0302]�ԋp�{�^��������\���s���Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVORowImpl;

/*******************************************************************************
 * SP�ꌈ���̕\�������̐ݒ���s�����߂̃��[�e�B���e�B�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionPropertyUtils 
{
  /*****************************************************************************
   * �\�������v���p�e�B�ݒ�
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param headerVo      SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param installVo     �ݒu��o�^�^�X�V�p�r���[�C���X�^���X
   * @param cntrctVo      �_���o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm1Vo         BM1�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm2Vo         BM2�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm3Vo         BM3�o�^�^�X�V�p�r���[�C���X�^���X
   * @param scVo          �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo       �S�e��ꗥ�����o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo       �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param attachVo      �Y�t�o�^�^�X�V�p�r���[�C���X�^���X
   * @param sendVo        �񑗐�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  public static void setAttributeProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // ������
    /////////////////////////////////////
    initializeProperty(
      initVo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
    );

    /////////////////////////////////////
    // �x�[�X�ݒ�
    /////////////////////////////////////
    setBaseProperty(
      initVo
     ,headerVo
     ,installVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,sendVo
    );

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    //////////////////////////////
    // �X�e�[�^�X�ɂ��\���^��\��
    //////////////////////////////
    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(headerRow.getStatus()) )
    {
      // �L��
      setEnableStatusProperty(
        initVo
       ,headerVo
       ,installVo
       ,cntrctVo
       ,bm1Vo
       ,bm2Vo
       ,bm3Vo
       ,scVo
       ,allCcVo
       ,selCcVo
       ,attachVo
      );

    }
    else
    {
      // �L���ȊO
      setDetailProperty(
        initVo
       ,headerVo
       ,installVo
       ,cntrctVo
       ,bm1Vo
       ,bm2Vo
       ,bm3Vo
       ,scVo
       ,allCcVo
       ,selCcVo
       ,attachVo
      );
    }

    setSendRegionProperty(
      initVo
     ,headerVo
     ,sendVo
    );
  }


  /*****************************************************************************
   * �\�������v���p�e�B�ڍאݒ�
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param headerVo      SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param installVo     �ݒu��o�^�^�X�V�p�r���[�C���X�^���X
   * @param cntrctVo      �_���o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm1Vo         BM1�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm2Vo         BM2�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm3Vo         BM3�o�^�^�X�V�p�r���[�C���X�^���X
   * @param scVo          �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo       �S�e��ꗥ�����o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo       �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param attachVo      �Y�t�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setDetailProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
  )
  {
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();

    String status              = headerRow.getStatus();
    String loginEmployeeNumber = initRow.getEmployeeNumber();
    String applicationCode     = headerRow.getApplicationCode();
    String applicationType     = headerRow.getApplicationType();
    String electricityType     = headerRow.getElectricityType();
    String custStatus          = installRow.getCustomerStatus();
    String sameInstAcctFlag    = cntrctRow.getSameInstallAccountFlag();
    String contractNumber      = cntrctRow.getContractNumber();
    String bm1SendType         = headerRow.getBm1SendType();
    String bm1VendorNumber     = bm1Row.getVendorNumber();
    String bm2VendorNumber     = bm2Row.getVendorNumber();
    String bm3VendorNumber     = bm3Row.getVendorNumber();
    
    /////////////////////////////////////
    // ��{��񃊁[�W����
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) )
    {
      initRow.setApplicationTypeViewRender(          Boolean.FALSE );
    }
    else
    {
      initRow.setApplicationTypeRender(              Boolean.FALSE );
    }

    /////////////////////////////////////
    // �ݒu���񃊁[�W����
    /////////////////////////////////////
    if ( ! loginEmployeeNumber.equals(applicationCode) )
    {
      // ���O�C�����[�U�[���\���҂łȂ��ꍇ�A
      // ���ׂē��͕s��
      initRow.setInstallAcctNumber1Render(         Boolean.FALSE );
      initRow.setInstallAcctNumber2Render(         Boolean.FALSE );
      initRow.setInstallPartyNameRender(           Boolean.FALSE );
      initRow.setInstallPartyNameAltRender(        Boolean.FALSE );
      initRow.setInstallNameRender(                Boolean.FALSE );
      initRow.setInstallPostCdFRender(             Boolean.FALSE );
      initRow.setInstallPostCdSRender(             Boolean.FALSE );
      initRow.setInstallStateRender(               Boolean.FALSE );
      initRow.setInstallCityRender(                Boolean.FALSE );
      initRow.setInstallAddress1Render(            Boolean.FALSE );
      initRow.setInstallAddress2Render(            Boolean.FALSE );
      initRow.setInstallAddressLineRender(         Boolean.FALSE );
      initRow.setBizCondTypeRender(                Boolean.FALSE );
      initRow.setBusinessTypeRender(               Boolean.FALSE );
      initRow.setInstallLocationRender(            Boolean.FALSE );
      initRow.setExtRefOpclTypeRender(             Boolean.FALSE );
      initRow.setEmployeeNumberRender(             Boolean.FALSE );
      initRow.setPublishBaseCodeRender(            Boolean.FALSE );
      initRow.setInstallDateRender(                Boolean.FALSE );
      initRow.setInstallDateRequiredRender(        Boolean.FALSE );
      initRow.setLeaseCompanyRender(               Boolean.FALSE );
    }
    else
    {
      initRow.setInstallAcctNumberViewRender(      Boolean.FALSE );
      initRow.setInstallDateViewRender(            Boolean.FALSE );
      initRow.setInstallDateRequiredViewRender(    Boolean.FALSE );
      initRow.setLeaseCompanyViewRender(           Boolean.FALSE );

      if ( custStatus == null                                              ||
           XxcsoSpDecisionConstants.CUST_STATUS_MC_CAND.equals(custStatus) ||
           XxcsoSpDecisionConstants.CUST_STATUS_MC.equals(custStatus)
         )
      {
        // �ڋq�X�e�[�^�X��NULL�i�V�K�j�AMC���AMC�̏ꍇ�A
        // ���͉\
        initRow.setInstallAcctNumber2Render(       Boolean.FALSE );
        initRow.setInstallPartyNameViewRender(     Boolean.FALSE );
        initRow.setInstallPartyNameAltViewRender(  Boolean.FALSE );
        initRow.setInstallNameViewRender(          Boolean.FALSE );
        initRow.setInstallPostCdFViewRender(       Boolean.FALSE );
        initRow.setInstallPostCdSViewRender(       Boolean.FALSE );
        initRow.setInstallStateViewRender(         Boolean.FALSE );
        initRow.setInstallCityViewRender(          Boolean.FALSE );
        initRow.setInstallAddress1ViewRender(      Boolean.FALSE );
        initRow.setInstallAddress2ViewRender(      Boolean.FALSE );
        initRow.setInstallAddressLineViewRender(   Boolean.FALSE );
        initRow.setBizCondTypeViewRender(          Boolean.FALSE );
        initRow.setBusinessTypeViewRender(         Boolean.FALSE );
        initRow.setInstallLocationViewRender(      Boolean.FALSE );
        initRow.setExtRefOpclTypeViewRender(       Boolean.FALSE );
        initRow.setEmployeeNumberViewRender(       Boolean.FALSE );
        initRow.setPublishBaseCodeViewRender(      Boolean.FALSE );
      }
      else
      {
        // �ڋq�X�e�[�^�X��NULL�i�V�K�j�AMC���AMC�ȊO�̏ꍇ�A
        // ���͕s��
        initRow.setInstallAcctNumber1Render(       Boolean.FALSE );
        initRow.setInstallPartyNameRender(         Boolean.FALSE );
        initRow.setInstallPartyNameAltRender(      Boolean.FALSE );
        initRow.setInstallNameRender(              Boolean.FALSE );
        initRow.setInstallPostCdFRender(           Boolean.FALSE );
        initRow.setInstallPostCdSRender(           Boolean.FALSE );
        initRow.setInstallStateRender(             Boolean.FALSE );
        initRow.setInstallCityRender(              Boolean.FALSE );
        initRow.setInstallAddress1Render(          Boolean.FALSE );
        initRow.setInstallAddress2Render(          Boolean.FALSE );
        initRow.setInstallAddressLineRender(       Boolean.FALSE );
        initRow.setBizCondTypeRender(              Boolean.FALSE );
        initRow.setBusinessTypeRender(             Boolean.FALSE );
        initRow.setInstallLocationRender(          Boolean.FALSE );
        initRow.setExtRefOpclTypeRender(           Boolean.FALSE );
        initRow.setEmployeeNumberRender(           Boolean.FALSE );
        initRow.setPublishBaseCodeRender(          Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // �_��惊�[�W����
    /////////////////////////////////////
    if ( "Y".equals(sameInstAcctFlag) )
    {
      // �ݒu��Ɠ����Ƀ`�F�b�N�������Ă���ꍇ�́A
      // ���͕s��
      // �������A�����ύX�̏ꍇ�́A
      // �_��於�A�_��於�J�i�͓��͉\
      initRow.setSameInstallAcctFlagViewRender(    Boolean.FALSE );
      initRow.setContractNumber1Render(            Boolean.FALSE );
      initRow.setContractNumber2Render(            Boolean.FALSE );
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
      {
        initRow.setContractNameRender(             Boolean.FALSE );
        initRow.setContractNameAltRender(          Boolean.FALSE );
      }
      else
      {
        initRow.setContractNameViewRender(         Boolean.FALSE );
        initRow.setContractNameAltViewRender(      Boolean.FALSE );
      }
      initRow.setContractPostCdFRender(            Boolean.FALSE );
      initRow.setContractPostCdSRender(            Boolean.FALSE );
      initRow.setContractStateRender(              Boolean.FALSE );
      initRow.setContractCityRender(               Boolean.FALSE );
      initRow.setContractAddress1Render(           Boolean.FALSE );
      initRow.setContractAddress2Render(           Boolean.FALSE );
      initRow.setContractAddressLineRender(        Boolean.FALSE );
      initRow.setDelegateNameViewRender(           Boolean.FALSE );
    }
    else
    {
      initRow.setContractNumberViewRender(         Boolean.FALSE );
      if ( contractNumber == null || "".equals(contractNumber) )
      {
        // �_���ԍ������͂���Ă��Ȃ��ꍇ�́A���͉\
        initRow.setSameInstallAcctFlagViewRender(  Boolean.FALSE );
        initRow.setContractNumber2Render(          Boolean.FALSE );
        initRow.setContractNameViewRender(         Boolean.FALSE );
        initRow.setContractNameAltViewRender(      Boolean.FALSE );
        initRow.setContractPostCdFViewRender(      Boolean.FALSE );
        initRow.setContractPostCdSViewRender(      Boolean.FALSE );
        initRow.setContractStateViewRender(        Boolean.FALSE );
        initRow.setContractCityViewRender(         Boolean.FALSE );
        initRow.setContractAddress1ViewRender(     Boolean.FALSE );
        initRow.setContractAddress2ViewRender(     Boolean.FALSE );
        initRow.setContractAddressLineViewRender(  Boolean.FALSE );
        initRow.setDelegateNameViewRender(         Boolean.FALSE );
      }
      else
      {
        initRow.setSameInstallAcctFlagRender(      Boolean.FALSE );
        initRow.setContractNumber1Render(          Boolean.FALSE );
        initRow.setContractNameRender(             Boolean.FALSE );
        initRow.setContractNameAltRender(          Boolean.FALSE );
        initRow.setContractPostCdFRender(          Boolean.FALSE );
        initRow.setContractPostCdSRender(          Boolean.FALSE );
        initRow.setContractStateRender(            Boolean.FALSE );
        initRow.setContractCityRender(             Boolean.FALSE );
        initRow.setContractAddress1Render(         Boolean.FALSE );
        initRow.setContractAddress2Render(         Boolean.FALSE );
        initRow.setContractAddressLineRender(      Boolean.FALSE );
        initRow.setDelegateNameRender(             Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // VD��񃊁[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
    initRow.setNewoldTypeViewRender(               Boolean.FALSE );
    initRow.setSeleNumberViewRender(               Boolean.FALSE );
    initRow.setMakerCodeViewRender(                Boolean.FALSE );
    initRow.setStandardTypeViewRender(             Boolean.FALSE );
    initRow.setUnNumberViewRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // ��������I�����[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
    initRow.setCondBizTypeViewRender(              Boolean.FALSE );

    /////////////////////////////////////
    // �����ʏ����I�����[�W����
    /////////////////////////////////////
    // ���ׂē��͉\

    /////////////////////////////////////
    // �ꗥ�����E�e��ʏ������[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
    initRow.setAllContainerTypeViewRender(         Boolean.FALSE );

    /////////////////////////////////////
    // ���̑��������[�W����
    /////////////////////////////////////
    initRow.setContractYearDateViewRender(         Boolean.FALSE );
    initRow.setInstallSupportAmtViewRender(        Boolean.FALSE );
    initRow.setInstallSupportAmt2ViewRender(       Boolean.FALSE );
    initRow.setPaymentCycleViewRender(             Boolean.FALSE );
    initRow.setElectricityTypeViewRender(          Boolean.FALSE );
    initRow.setElectricityAmountViewRender(        Boolean.FALSE );
    initRow.setConditionReasonViewRender(          Boolean.FALSE );

    /////////////////////////////////////
    // BM1���[�W����
    /////////////////////////////////////
    initRow.setBm1SendTypeViewRender(              Boolean.FALSE );
    if ( XxcsoSpDecisionConstants.SEND_SAME_INSTALL.equals(bm1SendType) ||
         XxcsoSpDecisionConstants.SEND_SAME_CNTRCT.equals(bm1SendType)
       )
    {
      // ���t�悪�ݒu��Ɠ����A�_���Ɠ����̏ꍇ�́A
      // ���t��A�U���萔�����S�A�x�������E���׏��ȊO�����͕s��
      initRow.setBm1VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm1VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm1VendorNameRender(              Boolean.FALSE );
      initRow.setBm1VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm1PostCdFRender(                 Boolean.FALSE );
      initRow.setBm1PostCdSRender(                 Boolean.FALSE );
      initRow.setBm1StateRender(                   Boolean.FALSE );
      initRow.setBm1CityRender(                    Boolean.FALSE );
      initRow.setBm1Address1Render(                Boolean.FALSE );
      initRow.setBm1Address2Render(                Boolean.FALSE );
      initRow.setBm1AddressLineRender(             Boolean.FALSE );
      initRow.setBm1TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm1PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm1VendorNumberViewRender(        Boolean.FALSE );
      if ( bm1VendorNumber == null || "".equals(bm1VendorNumber) )
      {
        // ���t��R�[�h��NULL�̏ꍇ�́A
        // ���͉\
        initRow.setBm1VendorNumber2Render(         Boolean.FALSE );
        initRow.setBm1VendorNameViewRender(        Boolean.FALSE );
        initRow.setBm1VendorNameAltViewRender(     Boolean.FALSE );
        initRow.setBm1PostCdFViewRender(           Boolean.FALSE );
        initRow.setBm1PostCdSViewRender(           Boolean.FALSE );
        initRow.setBm1StateViewRender(             Boolean.FALSE );
        initRow.setBm1CityViewRender(              Boolean.FALSE );
        initRow.setBm1Address1ViewRender(          Boolean.FALSE );
        initRow.setBm1Address2ViewRender(          Boolean.FALSE );
        initRow.setBm1AddressLineViewRender(       Boolean.FALSE );
        initRow.setBm1TransferTypeViewRender(      Boolean.FALSE );
        initRow.setBm1PaymentTypeViewRender(       Boolean.FALSE );
      }
      else
      {
        initRow.setBm1VendorNumber1Render(         Boolean.FALSE );
        initRow.setBm1VendorNameRender(            Boolean.FALSE );
        initRow.setBm1VendorNameAltRender(         Boolean.FALSE );
        initRow.setBm1PostCdFRender(               Boolean.FALSE );
        initRow.setBm1PostCdSRender(               Boolean.FALSE );
        initRow.setBm1StateRender(                 Boolean.FALSE );
        initRow.setBm1CityRender(                  Boolean.FALSE );
        initRow.setBm1Address1Render(              Boolean.FALSE );
        initRow.setBm1Address2Render(              Boolean.FALSE );
        initRow.setBm1AddressLineRender(           Boolean.FALSE );
        initRow.setBm1TransferTypeRender(          Boolean.FALSE );
        initRow.setBm1PaymentTypeRender(           Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // BM2���[�W����
    /////////////////////////////////////
    initRow.setBm2VendorNumberViewRender(          Boolean.FALSE );
    if ( bm2VendorNumber == null || "".equals(bm2VendorNumber) )
    {
      // ���t��R�[�h��NULL�̏ꍇ�́A
      // ���͉\
      initRow.setBm2VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm2VendorNameViewRender(          Boolean.FALSE );
      initRow.setBm2VendorNameAltViewRender(       Boolean.FALSE );
      initRow.setBm2PostCdFViewRender(             Boolean.FALSE );
      initRow.setBm2PostCdSViewRender(             Boolean.FALSE );
      initRow.setBm2StateViewRender(               Boolean.FALSE );
      initRow.setBm2CityViewRender(                Boolean.FALSE );
      initRow.setBm2Address1ViewRender(            Boolean.FALSE );
      initRow.setBm2Address2ViewRender(            Boolean.FALSE );
      initRow.setBm2AddressLineViewRender(         Boolean.FALSE );
      initRow.setBm2TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm2PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm2VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm2VendorNameRender(              Boolean.FALSE );
      initRow.setBm2VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm2PostCdFRender(                 Boolean.FALSE );
      initRow.setBm2PostCdSRender(                 Boolean.FALSE );
      initRow.setBm2StateRender(                   Boolean.FALSE );
      initRow.setBm2CityRender(                    Boolean.FALSE );
      initRow.setBm2Address1Render(                Boolean.FALSE );
      initRow.setBm2Address2Render(                Boolean.FALSE );
      initRow.setBm2AddressLineRender(             Boolean.FALSE );
      initRow.setBm2TransferTypeRender(            Boolean.FALSE );
      initRow.setBm2PaymentTypeRender(             Boolean.FALSE );
    }

    /////////////////////////////////////
    // BM3���[�W����
    /////////////////////////////////////
    initRow.setBm3VendorNumberViewRender(          Boolean.FALSE );
    if ( bm3VendorNumber == null || "".equals(bm3VendorNumber) )
    {
      // ���t��R�[�h��NULL�̏ꍇ�́A
      // ���͉\
      initRow.setBm3VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm3VendorNameViewRender(          Boolean.FALSE );
      initRow.setBm3VendorNameAltViewRender(       Boolean.FALSE );
      initRow.setBm3PostCdFViewRender(             Boolean.FALSE );
      initRow.setBm3PostCdSViewRender(             Boolean.FALSE );
      initRow.setBm3StateViewRender(               Boolean.FALSE );
      initRow.setBm3CityViewRender(                Boolean.FALSE );
      initRow.setBm3Address1ViewRender(            Boolean.FALSE );
      initRow.setBm3Address2ViewRender(            Boolean.FALSE );
      initRow.setBm3AddressLineViewRender(         Boolean.FALSE );
      initRow.setBm3TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm3PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm3VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm3VendorNameRender(              Boolean.FALSE );
      initRow.setBm3VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm3PostCdFRender(                 Boolean.FALSE );
      initRow.setBm3PostCdSRender(                 Boolean.FALSE );
      initRow.setBm3StateRender(                   Boolean.FALSE );
      initRow.setBm3CityRender(                    Boolean.FALSE );
      initRow.setBm3Address1Render(                Boolean.FALSE );
      initRow.setBm3Address2Render(                Boolean.FALSE );
      initRow.setBm3AddressLineRender(             Boolean.FALSE );
      initRow.setBm3TransferTypeRender(            Boolean.FALSE );
      initRow.setBm3PaymentTypeRender(             Boolean.FALSE );
    }

    /////////////////////////////////////
    // �_�񏑂ւ̋L�ڎ������[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
    initRow.setOtherContentViewRender(             Boolean.FALSE );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v���[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
    initRow.setSalesMonthViewRender(               Boolean.FALSE );
    initRow.setBmRateViewRender(                   Boolean.FALSE );
    initRow.setLeaseChargeMonthViewRender(         Boolean.FALSE );
    initRow.setConstructionChargeViewRender(       Boolean.FALSE );
    initRow.setElectricityAmtMonthViewRender(      Boolean.FALSE );

    /////////////////////////////////////
    // �Y�t���[�W����
    /////////////////////////////////////
    // ���ׂē��͉\
  }


  /*****************************************************************************
   * �L�����\�������v���p�e�B�ݒ�
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param headerVo      SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param installVo     �ݒu��o�^�^�X�V�p�r���[�C���X�^���X
   * @param cntrctVo      �_���o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm1Vo         BM1�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm2Vo         BM2�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm3Vo         BM3�o�^�^�X�V�p�r���[�C���X�^���X
   * @param scVo          �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo       �S�e��ꗥ�����o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo       �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param attachVo      �Y�t�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setEnableStatusProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
  )
  {
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    
    /////////////////////////////////////
    // ��{��񃊁[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setApplicationTypeRender(              Boolean.FALSE );

    /////////////////////////////////////
    // �ݒu���񃊁[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setInstallAcctNumber1Render(           Boolean.FALSE );
    initRow.setInstallAcctNumber2Render(           Boolean.FALSE );
    initRow.setInstallPartyNameRender(             Boolean.FALSE );
    initRow.setInstallPartyNameAltRender(          Boolean.FALSE );
    initRow.setInstallNameRender(                  Boolean.FALSE );
    initRow.setInstallPostCdFRender(               Boolean.FALSE );
    initRow.setInstallPostCdSRender(               Boolean.FALSE );
    initRow.setInstallStateRender(                 Boolean.FALSE );
    initRow.setInstallCityRender(                  Boolean.FALSE );
    initRow.setInstallAddress1Render(              Boolean.FALSE );
    initRow.setInstallAddress2Render(              Boolean.FALSE );
    initRow.setInstallAddressLineRender(           Boolean.FALSE );
    initRow.setBizCondTypeRender(                  Boolean.FALSE );
    initRow.setBusinessTypeRender(                 Boolean.FALSE );
    initRow.setInstallLocationRender(              Boolean.FALSE );
    initRow.setExtRefOpclTypeRender(               Boolean.FALSE );
    initRow.setEmployeeNumberRender(               Boolean.FALSE );
    initRow.setPublishBaseCodeRender(              Boolean.FALSE );
    initRow.setInstallDateRender(                  Boolean.FALSE );
    initRow.setInstallDateRequiredRender(          Boolean.FALSE );
    initRow.setLeaseCompanyRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // �_��惊�[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setSameInstallAcctFlagRender(          Boolean.FALSE );
    initRow.setContractNumber1Render(              Boolean.FALSE );
    initRow.setContractNumber2Render(              Boolean.FALSE );
    initRow.setContractNameRender(                 Boolean.FALSE );
    initRow.setContractNameAltRender(              Boolean.FALSE );
    initRow.setContractPostCdFRender(              Boolean.FALSE );
    initRow.setContractPostCdSRender(              Boolean.FALSE );
    initRow.setContractStateRender(                Boolean.FALSE );
    initRow.setContractCityRender(                 Boolean.FALSE );
    initRow.setContractAddress1Render(             Boolean.FALSE );
    initRow.setContractAddress2Render(             Boolean.FALSE );
    initRow.setContractAddressLineRender(          Boolean.FALSE );
    initRow.setDelegateNameRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // VD��񃊁[�W����
    /////////////////////////////////////
    if ( Boolean.TRUE.equals(initRow.getRequestButtonRender()) )
    {
      // �����˗��{�^���������郆�[�U�[�݂̂����͉\
      String newoldType = headerRow.getNewoldType();
      if ( XxcsoSpDecisionConstants.NEW_OLD_OLD.equals(newoldType) )
      {
        // ����̏ꍇ�́A���͕s��
        initRow.setNewoldTypeRender(               Boolean.FALSE );
      }
      else
      {
        initRow.setNewoldTypeViewRender(           Boolean.FALSE );
      }
      initRow.setSeleNumberViewRender(             Boolean.FALSE );
      initRow.setMakerCodeViewRender(              Boolean.FALSE );
      initRow.setStandardTypeViewRender(           Boolean.FALSE );
      initRow.setUnNumberViewRender(               Boolean.FALSE );
    }
    else
    {
      // �����˗��{�^���������Ȃ����[�U�[�͓��͕s��
      initRow.setNewoldTypeRender(                 Boolean.FALSE );
      initRow.setSeleNumberRender(                 Boolean.FALSE );
      initRow.setMakerCodeRender(                  Boolean.FALSE );
      initRow.setStandardTypeRender(               Boolean.FALSE );
      initRow.setUnNumberRender(                   Boolean.FALSE );
    }

    /////////////////////////////////////
    // ��������I�����[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setCondBizTypeRender(                  Boolean.FALSE );

    /////////////////////////////////////
    // �����ʏ����I�����[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setScActionFlRNRender(                 Boolean.FALSE );
    initRow.setScTableFooterRender(                Boolean.FALSE );
    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    while ( scRow != null )
    {
      scRow.setFixedPriceReadOnly(                 Boolean.TRUE  );
      scRow.setSalesPriceReadOnly(                 Boolean.TRUE  );
      scRow.setScBm1BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm1BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScBm2BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm2BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScBm3BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm3BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScMultipleSelectionRender(          Boolean.FALSE );
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    /////////////////////////////////////
    // �ꗥ�����E�e��ʏ������[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setAllContainerTypeRender(             Boolean.FALSE );
    initRow.setAllCcActionFlRNRender(              Boolean.FALSE );
    initRow.setSelCcActionFlRNRender(              Boolean.FALSE );

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    while ( allCcRow != null )
    {
      allCcRow.setAllDiscountAmtReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm1BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm1BmAmountReadOnly(        Boolean.TRUE  );
      allCcRow.setAllCcBm2BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm2BmAmountReadOnly(        Boolean.TRUE  );
      allCcRow.setAllCcBm3BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm3BmAmountReadOnly(        Boolean.TRUE  );
      
      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    while ( selCcRow != null )
    {
      selCcRow.setSelDiscountAmtReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm1BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm1BmAmountReadOnly(        Boolean.TRUE  );
      selCcRow.setSelCcBm2BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm2BmAmountReadOnly(        Boolean.TRUE  );
      selCcRow.setSelCcBm3BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm3BmAmountReadOnly(        Boolean.TRUE  );

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    /////////////////////////////////////
    // ���̑��������[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setContractYearDateRender(             Boolean.FALSE );
    initRow.setInstallSupportAmtRender(            Boolean.FALSE );
    initRow.setInstallSupportAmt2Render(           Boolean.FALSE );
    initRow.setPaymentCycleRender(                 Boolean.FALSE );
    initRow.setElectricityTypeRender(              Boolean.FALSE );
    initRow.setElectricityAmountRender(            Boolean.FALSE );
    initRow.setConditionReasonRender(              Boolean.FALSE );
    
    /////////////////////////////////////
    // BM1���[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setBm1SendTypeRender(                  Boolean.FALSE );
    initRow.setBm1VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm1VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm1VendorNameRender(                Boolean.FALSE );
    initRow.setBm1VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm1PostCdFRender(                   Boolean.FALSE );
    initRow.setBm1PostCdSRender(                   Boolean.FALSE );
    initRow.setBm1StateRender(                     Boolean.FALSE );
    initRow.setBm1CityRender(                      Boolean.FALSE );
    initRow.setBm1Address1Render(                  Boolean.FALSE );
    initRow.setBm1Address2Render(                  Boolean.FALSE );
    initRow.setBm1AddressLineRender(               Boolean.FALSE );
    initRow.setBm1TransferTypeRender(              Boolean.FALSE );
    initRow.setBm1PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // BM2���[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setBm2VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm2VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm2VendorNameRender(                Boolean.FALSE );
    initRow.setBm2VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm2PostCdFRender(                   Boolean.FALSE );
    initRow.setBm2PostCdSRender(                   Boolean.FALSE );
    initRow.setBm2StateRender(                     Boolean.FALSE );
    initRow.setBm2CityRender(                      Boolean.FALSE );
    initRow.setBm2Address1Render(                  Boolean.FALSE );
    initRow.setBm2Address2Render(                  Boolean.FALSE );
    initRow.setBm2AddressLineRender(               Boolean.FALSE );
    initRow.setBm2TransferTypeRender(              Boolean.FALSE );
    initRow.setBm2PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // BM3���[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setBm3VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm3VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm3VendorNameRender(                Boolean.FALSE );
    initRow.setBm3VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm3PostCdFRender(                   Boolean.FALSE );
    initRow.setBm3PostCdSRender(                   Boolean.FALSE );
    initRow.setBm3StateRender(                     Boolean.FALSE );
    initRow.setBm3CityRender(                      Boolean.FALSE );
    initRow.setBm3Address1Render(                  Boolean.FALSE );
    initRow.setBm3Address2Render(                  Boolean.FALSE );
    initRow.setBm3AddressLineRender(               Boolean.FALSE );
    initRow.setBm3TransferTypeRender(              Boolean.FALSE );
    initRow.setBm3PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // �_�񏑂ւ̋L�ڎ������[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setReflectContractButtonRender(        Boolean.FALSE );
    initRow.setOtherContentRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v���[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setCalcProfitButtonRender(             Boolean.FALSE );
    initRow.setSalesMonthRender(                   Boolean.FALSE );
    initRow.setBmRateRender(                       Boolean.FALSE );
    initRow.setLeaseChargeMonthRender(             Boolean.FALSE );
    initRow.setConstructionChargeRender(           Boolean.FALSE );
    initRow.setElectricityAmtMonthRender(          Boolean.FALSE );

    /////////////////////////////////////
    // �Y�t���[�W����
    /////////////////////////////////////
    // ���ׂē��͕s��
    initRow.setAttachActionFlRNRender(             Boolean.FALSE );

    attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    while ( attachRow != null )
    {
      attachRow.setExcerptReadOnly(                Boolean.TRUE  );
      attachRow.setAttachSelectionRender(          Boolean.FALSE );
      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }
  }


  /*****************************************************************************
   * �񑗐惊�[�W�����\�������v���p�e�B�ݒ�
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param sendVo        �񑗐�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setSendRegionProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    
    /////////////////////////////////////
    // �񑗐惊�[�W����
    /////////////////////////////////////
    // �����Ώۂ̃��[�U�[�̂݌��كR�����g����͉\
    // �����Ώۂ̃��[�U�[�ȍ~�͈̔́A�]�ƈ��ԍ�����͉\
    boolean duringFlag = false;
    String applicationCode      = headerRow.getApplicationCode();
    String loginEmployeeNumber  = initRow.getEmployeeNumber();
    String status               = headerRow.getStatus();

    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    while ( sendRow != null )
    {
      if ( applicationCode.equals(loginEmployeeNumber) )
      {
        // ���F�R�����g�ȊO
        // ���ׂē��͉\
        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );

        if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
        {
          // �X�e�[�^�X���L���̏ꍇ�́A���ׂē��͕s��
          sendRow.setRangeTypeReadOnly(            Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(          Boolean.TRUE  );
        }
        
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }
      
      String targetEmployeeNumber = sendRow.getApproveCode();
      String approvalStateType    = sendRow.getApprovalStateType();

      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
      {
        duringFlag = true;
        
        if ( loginEmployeeNumber.equals(targetEmployeeNumber) )
        {
          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
        }
        else
        {
          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
          sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );        
        }
      }
      else
      {
        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );
      }

      if ( ! duringFlag )
      {
        // ���F��ƒ����[�U�[�ȑO�̃��[�U�[�͓��͕s��
        sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
        sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );        
      }
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }
  }

  
  /*****************************************************************************
   * �\�������v���p�e�B��{�ݒ�
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param headerVo      SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param installVo     �ݒu��o�^�^�X�V�p�r���[�C���X�^���X
   * @param cntrctVo      �_���o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm1Vo         BM1�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm2Vo         BM2�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm3Vo         BM3�o�^�^�X�V�p�r���[�C���X�^���X
   * @param sendVo        �񑗐�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setBaseProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();

    /////////////////////////////////////
    //�\���敪�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String applicationType = headerRow.getApplicationType();
    if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
    {
      initRow.setInstallDateRender(                  Boolean.FALSE );
      initRow.setInstallDateViewRender(              Boolean.FALSE );
    }
    else
    {
      initRow.setInstallDateRequiredRender(          Boolean.FALSE );
      initRow.setInstallDateRequiredViewRender(      Boolean.FALSE );
    }

    /////////////////////////////////////
    // �Ƒԁi�����ށj�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String bizCondType = installRow.getBusinessConditionType();
    if ( bizCondType == null || "".equals(bizCondType) )
    {
      initRow.setBm1InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
      initRow.setBm3InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    if ( XxcsoSpDecisionConstants.BIZ_COND_OFF_SET_VD.equals(bizCondType) )
    {
      initRow.setBm1InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
      initRow.setBm3InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    //�V�䋌��敪�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String newoldType = headerRow.getNewoldType();
    if ( XxcsoSpDecisionConstants.NEW_OLD_NEW.equals(newoldType) )
    {
      initRow.setVdInfo3LayoutRender(                Boolean.FALSE );
    }
    else
    {
      initRow.setVdInfo3RequiredLayoutRender(        Boolean.FALSE );
    }

    /////////////////////////////////////
    // ��������ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String condBizType = headerRow.getConditionBusinessType();
    if ( condBizType == null || "".equals(condBizType) )
    {
      // �I������Ă��Ȃ��ꍇ�́A�w�b�_���[�W�������Ɣ�\��
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_NON_PAY_BM.equals(condBizType) )
    {
      // BM�x���Ȃ��̏ꍇ�́A�w�b�_���[�W�������Ɣ�\��
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }
    
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType) )
    {
      // �����ʏ����̏ꍇ�́A�ꗥ�����E�e��ʏ����w�b�_���Ɣ�\��
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      // ��t�����\��
      initRow.setScContributeGrpRender(              Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
    {
      // �����ʏ����i��t���o�^�p�j�̏ꍇ�́A�ꗥ�����E�e��ʏ����w�b�_���Ɣ�\��
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      // BM2���\��
      initRow.setScBm2GrpRender(                     Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType) )
    {
      // �ꗥ�����E�e��ʏ����̏ꍇ�́A�����ʏ����w�b�_���Ɣ�\��
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      // ��t�����\��
      initRow.setAllCcContributeGrpRender(           Boolean.FALSE );
      initRow.setSelCcContributeGrpRender(           Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      // �ꗥ�����E�e��ʏ����̏ꍇ�́A�����ʏ����w�b�_���Ɣ�\��
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      // BM2���\��
      initRow.setAllCcBm2GrpRender(                  Boolean.FALSE );
      initRow.setSelCcBm2GrpRender(                  Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // �S�e��敪�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String allContainerType = headerRow.getAllContainerType();
    if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
    {
      // �S�e��ꗥ���������̏ꍇ�́A�e��ʏ����e�[�u�����\��
      initRow.setSelCcAdvTblRNRender(                Boolean.FALSE );
    }
    else
    {
      // �e��ʏ����̏ꍇ�́A�S�e��ꗥ�����e�[�u�����\��
      initRow.setAllCcAdvTblRNRender(                Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // �d�C��敪�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String elecType = headerRow.getElectricityType();
    if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType)    ||
         XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(elecType)
       )
    {
      initRow.setElecStartLabelRender(               Boolean.FALSE );
    }
    else
    {
      initRow.setElecStartRequiredLabelRender(       Boolean.FALSE );
      initRow.setElectricityAmountRender(            Boolean.FALSE );
      initRow.setElectricityAmountViewRender(        Boolean.FALSE );
      initRow.setElecAmountLabelRender(              Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // �x�������E���׏��iBM1�j�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String bm1PaymentType = bm1Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
    {
      // �x�������E���׏��iBM1�j���x���Ȃ��̏ꍇ�́A
      // �x�������E���׏��iBM1�j�ȊO���\��
      initRow.setBm1SendTypeRender(                  Boolean.FALSE );
      initRow.setBm1SendTypeViewRender(              Boolean.FALSE );
      initRow.setBm1VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm1VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm1VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm1VendorNameRender(                Boolean.FALSE );
      initRow.setBm1VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm1VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm1VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm1PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm1StateRender(                     Boolean.FALSE );
      initRow.setBm1StateViewRender(                 Boolean.FALSE );
      initRow.setBm1CityRender(                      Boolean.FALSE );
      initRow.setBm1CityViewRender(                  Boolean.FALSE );
      initRow.setBm1Address1Render(                  Boolean.FALSE );
      initRow.setBm1Address1ViewRender(              Boolean.FALSE );
      initRow.setBm1Address2Render(                  Boolean.FALSE );
      initRow.setBm1Address2ViewRender(              Boolean.FALSE );
      initRow.setBm1AddressLineRender(               Boolean.FALSE );
      initRow.setBm1AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm1TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm1InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // �x�������E���׏��iBM2�j�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
    {
      // �x�������E���׏��iBM2�j���x���Ȃ��̏ꍇ�́A
      // �x�������E���׏��iBM2�j�ȊO���\��
      initRow.setBm2VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm2VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm2VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm2VendorNameRender(                Boolean.FALSE );
      initRow.setBm2VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm2VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm2VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm2PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm2StateRender(                     Boolean.FALSE );
      initRow.setBm2StateViewRender(                 Boolean.FALSE );
      initRow.setBm2CityRender(                      Boolean.FALSE );
      initRow.setBm2CityViewRender(                  Boolean.FALSE );
      initRow.setBm2Address1Render(                  Boolean.FALSE );
      initRow.setBm2Address1ViewRender(              Boolean.FALSE );
      initRow.setBm2Address2Render(                  Boolean.FALSE );
      initRow.setBm2Address2ViewRender(              Boolean.FALSE );
      initRow.setBm2AddressLineRender(               Boolean.FALSE );
      initRow.setBm2AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm2TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm2InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // �x�������E���׏��iBM3�j�ɂ��A�\���^��\����ݒ�
    /////////////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
    {
      // �x�������E���׏��iBM3�j���x���Ȃ��̏ꍇ�́A
      // �x�������E���׏��iBM3�j�ȊO���\��
      initRow.setBm3VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm3VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm3VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm3VendorNameRender(                Boolean.FALSE );
      initRow.setBm3VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm3VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm3VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm3PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm3StateRender(                     Boolean.FALSE );
      initRow.setBm3StateViewRender(                 Boolean.FALSE );
      initRow.setBm3CityRender(                      Boolean.FALSE );
      initRow.setBm3CityViewRender(                  Boolean.FALSE );
      initRow.setBm3Address1Render(                  Boolean.FALSE );
      initRow.setBm3Address1ViewRender(              Boolean.FALSE );
      initRow.setBm3Address2Render(                  Boolean.FALSE );
      initRow.setBm3Address2ViewRender(              Boolean.FALSE );
      initRow.setBm3AddressLineRender(               Boolean.FALSE );
      initRow.setBm3AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm3TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm3InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // �d�C��̃X�y�[�T�̕\���^��\����ݒ�
    /////////////////////////////////////
    String cntrctElecAmtView = headerRow.getElectricityAmountView();
    if ( cntrctElecAmtView == null || "".equals(cntrctElecAmtView) )
    {
      initRow.setCntrctElecSpacer2Render(            Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // �{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    boolean firstFlag   = false;
    boolean submitFlag  = true;
    boolean confirmFlag = false;
    boolean approveFlag = false;
    String loginEmployeeNumber = initRow.getEmployeeNumber();
// 2009-04-20 [ST��QT1_0302] Add Start
    boolean contReturnSelfFlag = false;
// 2009-04-20 [ST��QT1_0302] Add End
    while ( sendRow != null )
    {
      String approveCode = sendRow.getApproveCode();
      if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
      {
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      String approvalStateType = sendRow.getApprovalStateType();
      if ( ! firstFlag )
      {
        firstFlag = true;
        if ( ! XxcsoSpDecisionConstants.APPR_NONE.equals(approvalStateType) )
        {
          submitFlag = false;
        }
      }

      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
      {
        if ( approveCode.equals(loginEmployeeNumber) )
        {
          String workRequestType = sendRow.getWorkRequestType();
          if ( XxcsoSpDecisionConstants.REQ_APPROVE.equals(workRequestType) )
          {
            approveFlag = true;
          }
          else
          {
            confirmFlag = true;
          }
        }
      }
// 2009-04-20 [ST��QT1_0302] Add Start
      String approvalContent = sendRow.getApprovalContent();
      if ( XxcsoSpDecisionConstants.APPR_CONT_RETURN.equals( approvalContent ) )
      {
        if ( approveCode.equals( loginEmployeeNumber ) )
        {
          contReturnSelfFlag = true;
        }
        else
        {
          contReturnSelfFlag = false;
        }
      }
// 2009-04-20 [ST��QT1_0302] Add End
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }
    
    /////////////////////////////////////
    // �K�p�{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    String appBaseCode = headerRow.getAppBaseCode();
    String loginBaseCode = initRow.getBaseCode();
    if ( appBaseCode   == null               ||
         loginBaseCode == null               ||
         ! appBaseCode.equals(loginBaseCode)
       )
    {
      // ���_�R�[�h����v���Ȃ��ꍇ�́A�K�p�{�^�����\��
      initRow.setApplyButtonRender(                  Boolean.FALSE );
    }

    String status = headerRow.getStatus();
    if ( ! XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) )
    {
      // �X�e�[�^�X�����͒��ȊO�̏ꍇ�́A�K�p�{�^�����\��
      initRow.setApplyButtonRender(                  Boolean.FALSE );
    }

    /////////////////////////////////////
    // ��o�{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    if ( appBaseCode   == null               ||
         loginBaseCode == null               ||
         ! appBaseCode.equals(loginBaseCode)
       )
    {
      // ���_�R�[�h����v���Ȃ��ꍇ�́A��o�{�^�����\��
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }

    if ( ! submitFlag )
    {
      // SP�ꌈ�񑗓��̍ŏ��̏��F�K�w�ɕR�Â�SP�ꌈ�񑗐��
      // ���ُ�Ԃ��u�������v�łȂ��ꍇ�́A��o�{�^�����\��
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }
    
    if ( ! XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) &&
         ! XxcsoSpDecisionConstants.STATUS_REJECT.equals(status)
       )
    {
      // �X�e�[�^�X�����͒��A�ی��ȊO�̏ꍇ�́A��o�{�^�����\��
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }

// 2009-04-20 [ST��QT1_0302] Add Start
    if ( contReturnSelfFlag )
    {
      // ���ٓ��e���ԋp�̏ꍇ�͒�o�{�^�����\��
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }
// 2009-04-20 [ST��QT1_0302] Add End

    /////////////////////////////////////
    // �m�F�{�^���A�ԋp�{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    if ( ! confirmFlag )
    {
      // ���ُ�ԋ敪���������łȂ��ꍇ�́A
      // �m�F�{�^���A�ԋp�{�^�����\��
      initRow.setConfirmButtonRender(                Boolean.FALSE );
      initRow.setReturnButtonRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      // �X�e�[�^�X���L���̏ꍇ�́A
      // �ԋp�{�^�����\��
      initRow.setReturnButtonRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // ���F�{�^���A�ی��{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    if ( ! approveFlag )
    {
      // ���ُ�ԋ敪���������łȂ��ꍇ�́A
      // ���F�{�^���A�ی��{�^�����\��
      initRow.setApproveButtonRender(                Boolean.FALSE );
      initRow.setRejectButtonRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      // �X�e�[�^�X���L���̏ꍇ�́A
      // �ی��{�^�����\��
      initRow.setRejectButtonRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // �����˗��{�^���̕\���^��\����ݒ�
    /////////////////////////////////////
    String publishBaseCode = installRow.getPublishBaseCode();
    boolean requestEnabledFlag = false;
    
    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      if ( loginBaseCode != null )
      {
        if ( loginBaseCode.equals(appBaseCode) )
        {
          // �X�e�[�^�X���L���ŁA
          // ���O�C�����[�U�[�̋��_�R�[�h�Ɛ\�����_�������ꍇ�́A
          // �����˗��{�^���͕\��
          requestEnabledFlag = true;
        }

        if ( loginBaseCode.equals(publishBaseCode) )
        {
          // �X�e�[�^�X���L���ŁA
          // ���O�C�����[�U�[�̋��_�R�[�h�ƒS�����_�������ꍇ�́A
          // �����˗��{�^���͕\��
          requestEnabledFlag = true;
        }
      }
    }

    if ( ! requestEnabledFlag )
    {
      initRow.setRequestButtonRender(                Boolean.FALSE );
    }
  }



  
  /*****************************************************************************
   * �\�������v���p�e�B������
   * @param initVo        SP�ꌈ�������p�r���[�C���X�^���X
   * @param scVo          �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo       �S�e��ꗥ�o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo       �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param attachVo      �Y�t�o�^�^�X�V�p�r���[�C���X�^���X
   * @param sendVo        �񑗐�o�^�^�X�V�p�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void initializeProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();

    /////////////////////////////////////
    // ������
    /////////////////////////////////////
      // ��{��񃊁[�W����
    initRow.setApplicationTypeRender(            Boolean.TRUE  );
    initRow.setApplicationTypeViewRender(        Boolean.TRUE  );
    
      // �ݒu���񃊁[�W����
    initRow.setInstallAcctNumber1Render(         Boolean.TRUE  );
    initRow.setInstallAcctNumber2Render(         Boolean.TRUE  );
    initRow.setInstallAcctNumberViewRender(      Boolean.TRUE  );
    initRow.setInstallPartyNameRender(           Boolean.TRUE  );
    initRow.setInstallPartyNameViewRender(       Boolean.TRUE  );
    initRow.setInstallPartyNameAltRender(        Boolean.TRUE  );
    initRow.setInstallPartyNameAltViewRender(    Boolean.TRUE  );
    initRow.setInstallNameRender(                Boolean.TRUE  );
    initRow.setInstallNameViewRender(            Boolean.TRUE  );
    initRow.setInstallPostCdFRender(             Boolean.TRUE  );
    initRow.setInstallPostCdFViewRender(         Boolean.TRUE  );
    initRow.setInstallPostCdSRender(             Boolean.TRUE  );
    initRow.setInstallPostCdSViewRender(         Boolean.TRUE  );
    initRow.setInstallStateRender(               Boolean.TRUE  );
    initRow.setInstallStateViewRender(           Boolean.TRUE  );
    initRow.setInstallCityRender(                Boolean.TRUE  );
    initRow.setInstallCityViewRender(            Boolean.TRUE  );
    initRow.setInstallAddress1Render(            Boolean.TRUE  );
    initRow.setInstallAddress1ViewRender(        Boolean.TRUE  );
    initRow.setInstallAddress2Render(            Boolean.TRUE  );
    initRow.setInstallAddress2ViewRender(        Boolean.TRUE  );
    initRow.setInstallAddressLineRender(         Boolean.TRUE  );
    initRow.setInstallAddressLineViewRender(     Boolean.TRUE  );
    initRow.setBizCondTypeRender(                Boolean.TRUE  );
    initRow.setBizCondTypeViewRender(            Boolean.TRUE  );
    initRow.setBusinessTypeRender(               Boolean.TRUE  );
    initRow.setBusinessTypeViewRender(           Boolean.TRUE  );
    initRow.setInstallLocationRender(            Boolean.TRUE  );
    initRow.setInstallLocationViewRender(        Boolean.TRUE  );
    initRow.setExtRefOpclTypeRender(             Boolean.TRUE  );
    initRow.setExtRefOpclTypeViewRender(         Boolean.TRUE  );
    initRow.setEmployeeNumberRender(             Boolean.TRUE  );
    initRow.setEmployeeNumberViewRender(         Boolean.TRUE  );
    initRow.setPublishBaseCodeRender(            Boolean.TRUE  );
    initRow.setPublishBaseCodeViewRender(        Boolean.TRUE  );
    initRow.setInstallDateRequiredRender(        Boolean.TRUE  );
    initRow.setInstallDateRequiredViewRender(    Boolean.TRUE  );
    initRow.setInstallDateRender(                Boolean.TRUE  );
    initRow.setInstallDateViewRender(            Boolean.TRUE  );
    initRow.setLeaseCompanyRender(               Boolean.TRUE  );
    initRow.setLeaseCompanyViewRender(           Boolean.TRUE  );

    // �_��惊�[�W����
    initRow.setSameInstallAcctFlagRender(        Boolean.TRUE  );
    initRow.setSameInstallAcctFlagViewRender(    Boolean.TRUE  );
    initRow.setContractNumber1Render(            Boolean.TRUE  );
    initRow.setContractNumber2Render(            Boolean.TRUE  );
    initRow.setContractNumberViewRender(         Boolean.TRUE  );
    initRow.setContractNameRender(               Boolean.TRUE  );
    initRow.setContractNameViewRender(           Boolean.TRUE  );
    initRow.setContractNameAltRender(            Boolean.TRUE  );
    initRow.setContractNameAltViewRender(        Boolean.TRUE  );
    initRow.setContractPostCdFRender(            Boolean.TRUE  );
    initRow.setContractPostCdFViewRender(        Boolean.TRUE  );
    initRow.setContractPostCdSRender(            Boolean.TRUE  );
    initRow.setContractPostCdSViewRender(        Boolean.TRUE  );
    initRow.setContractStateRender(              Boolean.TRUE  );
    initRow.setContractStateViewRender(          Boolean.TRUE  );
    initRow.setContractCityRender(               Boolean.TRUE  );
    initRow.setContractCityViewRender(           Boolean.TRUE  );
    initRow.setContractAddress1Render(           Boolean.TRUE  );
    initRow.setContractAddress1ViewRender(       Boolean.TRUE  );
    initRow.setContractAddress2Render(           Boolean.TRUE  );
    initRow.setContractAddress2ViewRender(       Boolean.TRUE  );
    initRow.setContractAddressLineRender(        Boolean.TRUE  );
    initRow.setContractAddressLineViewRender(    Boolean.TRUE  );
    initRow.setDelegateNameRender(               Boolean.TRUE  );
    initRow.setDelegateNameViewRender(           Boolean.TRUE  );

    // VD��񃊁[�W����
    initRow.setNewoldTypeRender(                 Boolean.TRUE  );
    initRow.setNewoldTypeViewRender(             Boolean.TRUE  );
    initRow.setSeleNumberRender(                 Boolean.TRUE  );
    initRow.setSeleNumberViewRender(             Boolean.TRUE  );
    initRow.setMakerCodeRender(                  Boolean.TRUE  );
    initRow.setMakerCodeViewRender(              Boolean.TRUE  );
    initRow.setStandardTypeRender(               Boolean.TRUE  );
    initRow.setStandardTypeViewRender(           Boolean.TRUE  );
    initRow.setVdInfo3LayoutRender(              Boolean.TRUE  );
    initRow.setVdInfo3RequiredLayoutRender(      Boolean.TRUE  );
    initRow.setUnNumberRender(                   Boolean.TRUE  );
    initRow.setUnNumberViewRender(               Boolean.TRUE  );

    // ��������I�����[�W����
    initRow.setCondBizTypeRender(                Boolean.TRUE  );
    initRow.setCondBizTypeViewRender(            Boolean.TRUE  );

    // �����ʏ������[�W����
    initRow.setSalesConditionHdrRNRender(        Boolean.TRUE  );
    initRow.setScActionFlRNRender(               Boolean.TRUE  );
    initRow.setScTableFooterRender(              Boolean.TRUE  );
    initRow.setScBm2GrpRender(                   Boolean.TRUE  );
    initRow.setScContributeGrpRender(            Boolean.TRUE  );
    
    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    while ( scRow != null )
    {
      scRow.setScMultipleSelectionRender(        Boolean.TRUE  );
      scRow.setFixedPriceReadOnly(               Boolean.FALSE );
      scRow.setSalesPriceReadOnly(               Boolean.FALSE );
      scRow.setScBm1BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm1BmAmountReadOnly(            Boolean.FALSE );
      scRow.setScBm2BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm2BmAmountReadOnly(            Boolean.FALSE );
      scRow.setScBm3BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm3BmAmountReadOnly(            Boolean.FALSE );
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    // �ꗥ�����E�e��ʏ������[�W����
    initRow.setContainerConditionHdrRNRender(    Boolean.TRUE  );
    initRow.setAllContainerTypeRender(           Boolean.TRUE  );
    initRow.setAllContainerTypeViewRender(       Boolean.TRUE  );
    
    // �ꗥ�����E�e��ʏ������[�W�����i�S�e��j
    initRow.setAllCcAdvTblRNRender(              Boolean.TRUE  );
    initRow.setAllCcActionFlRNRender(            Boolean.TRUE  );
    initRow.setAllCcBm2GrpRender(                Boolean.TRUE  );
    initRow.setAllCcContributeGrpRender(         Boolean.TRUE  );

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    while ( allCcRow != null )
    {
      allCcRow.setAllDiscountAmtReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm1BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm1BmAmountReadOnly(      Boolean.FALSE );
      allCcRow.setAllCcBm2BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm2BmAmountReadOnly(      Boolean.FALSE );
      allCcRow.setAllCcBm3BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm3BmAmountReadOnly(      Boolean.FALSE );

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    // �ꗥ�����E�e��ʏ������[�W�����i�S�e��ȊO�j
    initRow.setSelCcAdvTblRNRender(              Boolean.TRUE  );
    initRow.setSelCcActionFlRNRender(            Boolean.TRUE  );
    initRow.setSelCcBm2GrpRender(                Boolean.TRUE  );
    initRow.setSelCcContributeGrpRender(         Boolean.TRUE  );

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    while ( selCcRow != null )
    {
      selCcRow.setSelDiscountAmtReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm1BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm1BmAmountReadOnly(      Boolean.FALSE );
      selCcRow.setSelCcBm2BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm2BmAmountReadOnly(      Boolean.FALSE );
      selCcRow.setSelCcBm3BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm3BmAmountReadOnly(      Boolean.FALSE );

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    // ���̑��������[�W����
    initRow.setContractYearDateRender(           Boolean.TRUE  );
    initRow.setContractYearDateViewRender(       Boolean.TRUE  );
    initRow.setInstallSupportAmtRender(          Boolean.TRUE  );
    initRow.setInstallSupportAmtViewRender(      Boolean.TRUE  );
    initRow.setInstallSupportAmt2Render(         Boolean.TRUE  );
    initRow.setInstallSupportAmt2ViewRender(     Boolean.TRUE  );
    initRow.setPaymentCycleRender(               Boolean.TRUE  );
    initRow.setPaymentCycleViewRender(           Boolean.TRUE  );
    initRow.setElecStartLabelRender(             Boolean.TRUE  );
    initRow.setElecStartRequiredLabelRender(     Boolean.TRUE  );
    initRow.setElectricityTypeRender(            Boolean.TRUE  );
    initRow.setElectricityTypeViewRender(        Boolean.TRUE  );
    initRow.setElectricityAmountRender(          Boolean.TRUE  );
    initRow.setElectricityAmountViewRender(      Boolean.TRUE  );
    initRow.setElecAmountLabelRender(            Boolean.TRUE  );
    initRow.setConditionReasonRender(            Boolean.TRUE  );
    initRow.setConditionReasonViewRender(        Boolean.TRUE  );

    // BM1���[�W����
    initRow.setBm1InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setBm1SendTypeRender(                Boolean.TRUE  );
    initRow.setBm1SendTypeViewRender(            Boolean.TRUE  );
    initRow.setBm1VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm1VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm1VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm1VendorNameRender(              Boolean.TRUE  );
    initRow.setBm1VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm1VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm1VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm1TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm1TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm1TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm1PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm1PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm1InquiryBaseLayoutRender(       Boolean.TRUE  );
    initRow.setBm1PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm1PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm1PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm1PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm1PostCdSViewRender(             Boolean.TRUE  );
    initRow.setBm1StateRender(                   Boolean.TRUE  );
    initRow.setBm1StateViewRender(               Boolean.TRUE  );
    initRow.setBm1CityRender(                    Boolean.TRUE  );
    initRow.setBm1CityViewRender(                Boolean.TRUE  );
    initRow.setBm1Address1Render(                Boolean.TRUE  );
    initRow.setBm1Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm1Address2Render(                Boolean.TRUE  );
    initRow.setBm1Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm1AddressLineRender(             Boolean.TRUE  );
    initRow.setBm1AddressLineViewRender(         Boolean.TRUE  );

    // BM2���[�W����
    initRow.setBm2InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setContributeInfoHdrRNRender(        Boolean.TRUE  );
    initRow.setBm2VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm2VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm2VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm2VendorNameRender(              Boolean.TRUE  );
    initRow.setBm2VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm2VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm2VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm2PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm2PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm2PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm2PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm2PostCdSViewRender(             Boolean.TRUE  );
    initRow.setBm2StateRender(                   Boolean.TRUE  );
    initRow.setBm2StateViewRender(               Boolean.TRUE  );
    initRow.setBm2CityRender(                    Boolean.TRUE  );
    initRow.setBm2CityViewRender(                Boolean.TRUE  );
    initRow.setBm2Address1Render(                Boolean.TRUE  );
    initRow.setBm2Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm2Address2Render(                Boolean.TRUE  );
    initRow.setBm2Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm2AddressLineRender(             Boolean.TRUE  );
    initRow.setBm2AddressLineViewRender(         Boolean.TRUE  );
    initRow.setBm2TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm2TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm2TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm2PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm2PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm2InquiryBaseLayoutRender(       Boolean.TRUE  );

    // BM3���[�W����
    initRow.setBm3InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setBm3VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm3VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm3VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm3VendorNameRender(              Boolean.TRUE  );
    initRow.setBm3VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm3VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm3VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm3PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm3PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm3PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm3PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm3PostCdSViewRender(             Boolean.TRUE  );
    initRow.setBm3StateRender(                   Boolean.TRUE  );
    initRow.setBm3StateViewRender(               Boolean.TRUE  );
    initRow.setBm3CityRender(                    Boolean.TRUE  );
    initRow.setBm3CityViewRender(                Boolean.TRUE  );
    initRow.setBm3Address1Render(                Boolean.TRUE  );
    initRow.setBm3Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm3Address2Render(                Boolean.TRUE  );
    initRow.setBm3Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm3AddressLineRender(             Boolean.TRUE  );
    initRow.setBm3AddressLineViewRender(         Boolean.TRUE  );
    initRow.setBm3TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm3TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm3TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm3PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm3PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm3InquiryBaseLayoutRender(       Boolean.TRUE  );

    // �_�񏑂ւ̋L�ڎ������[�W����
    initRow.setReflectContractButtonRender(      Boolean.TRUE  );
    initRow.setCntrctElecSpacer2Render(          Boolean.TRUE  );
    initRow.setOtherContentRender(               Boolean.TRUE  );
    initRow.setOtherContentViewRender(           Boolean.TRUE  );

    // �T�Z�N�ԑ��v���[�W����
    initRow.setCalcProfitButtonRender(           Boolean.TRUE  );
    initRow.setSalesMonthRender(                 Boolean.TRUE  );
    initRow.setSalesMonthViewRender(             Boolean.TRUE  );
    initRow.setBmRateRender(                     Boolean.TRUE  );
    initRow.setBmRateViewRender(                 Boolean.TRUE  );
    initRow.setLeaseChargeMonthRender(           Boolean.TRUE  );
    initRow.setLeaseChargeMonthViewRender(       Boolean.TRUE  );
    initRow.setConstructionChargeRender(         Boolean.TRUE  );
    initRow.setConstructionChargeViewRender(     Boolean.TRUE  );
    initRow.setElectricityAmtMonthRender(        Boolean.TRUE  );
    initRow.setElectricityAmtMonthViewRender(    Boolean.TRUE  );

    // �Y�t���[�W����
    initRow.setAttachActionFlRNRender(           Boolean.TRUE  );

    attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    while ( attachRow != null )
    {
      attachRow.setExcerptReadOnly(              Boolean.FALSE );
      
      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }
    
    // �񑗐惊�[�W����
    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    while ( sendRow != null )
    {
      sendRow.setRangeTypeReadOnly(              Boolean.FALSE );
      sendRow.setApprovalCommentReadOnly(        Boolean.FALSE );
      sendRow.setApprovalCommentReadOnly(        Boolean.FALSE );
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }

    // �{�^��
    initRow.setApplyButtonRender(                Boolean.TRUE  );
    initRow.setSubmitButtonRender(               Boolean.TRUE  );
    initRow.setRejectButtonRender(               Boolean.TRUE  );
    initRow.setApproveButtonRender(              Boolean.TRUE  );
    initRow.setReturnButtonRender(               Boolean.TRUE  );
    initRow.setConfirmButtonRender(              Boolean.TRUE  );
    initRow.setRequestButtonRender(              Boolean.TRUE  );
  }
}