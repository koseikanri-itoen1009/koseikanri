/*============================================================================
* �t�@�C���� : XxcsoSpDecisionValidateUtils
* �T�v����   : SP�ꌈ�o�^��ʗp���؃��[�e�B���e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS����_     �V�K�쐬
* 2009-03-04 1.1  SCS����_     �ۑ�ꗗNo.73�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;

/*******************************************************************************
 * SP�ꌈ���o�^��ʗp�̃f�[�^�����؂��邽�߂̃��[�e�B���e�B�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionValidateUtils 
{
  /*****************************************************************************
   * �ݒu��̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param installVo   �ݒu��o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateInstallCust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String applicationType = headerRow.getApplicationType();
    
    /////////////////////////////////////
    // �ݒu��F�ڋq��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,installRow.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPartyName()
         ,token1
         ,0
        );
    
    /////////////////////////////////////
    // �ݒu��F�ڋq���i�J�i�j
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME_ALT;
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPartyNameAlt()
         ,token1
         ,0
        );
    if ( ! isDoubleByteKana(
             txn
            ,installRow.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00286
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INST_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
    
    /////////////////////////////////////
    // �ݒu��F�X�֔ԍ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( installRow.getPostalCodeFirst() == null             ||
           "".equals(installRow.getPostalCodeFirst().trim())   ||
           installRow.getPostalCodeSecond() == null            ||
           "".equals(installRow.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,installRow.getPostalCodeFirst()
              ,installRow.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // �ݒu��F�s���{��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getState()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �ݒu��F�s�E��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getCity()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �ݒu��F�Z��1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getAddress1()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �ݒu��F�Z��2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getAddress2()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �ݒu��F�d�b�ԍ�
    /////////////////////////////////////
    if ( ! utils.isTelNumber(installRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // �ݒu��F�Ƒԁi�����ށj
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BUSINESS_CONDITION;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getBusinessConditionType()
           ,token1
           ,0
          );
    }
    
    /////////////////////////////////////
    // �ݒu��F�Ǝ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BUSINESS_TYPE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getBusinessType()
           ,token1
           ,0
          );
    }
    
    /////////////////////////////////////
    // �ݒu��F�ݒu�ꏊ
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_LOCATION;
    if ( submitFlag )
    {
      String installLocation = installRow.getInstallLocation();
      String extRefOpclType = installRow.getExternalReferenceOpclType();
      if ( installLocation == null    ||
           "".equals(installLocation) ||
           extRefOpclType == null     ||
           "".equals(extRefOpclType)
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }
    }
    
    /////////////////////////////////////
    // �ݒu��F�Ј���
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_EMPLOYEES;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,installRow.getEmployeeNumber()
         ,token1
         ,0
         ,7
         ,true
         ,true
         ,false
         ,0
        );
    
    /////////////////////////////////////
    // �ݒu��F�S�����_
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_PUBLISHED_BASE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,installRow.getPublishBaseCode()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,installRow.getPublishBaseCode()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �ݒu��F�ݒu��
    /////////////////////////////////////
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_DATE;
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getInstallDate()
             ,token1
             ,0
            );
      }
    }

    /////////////////////////////////////
    // �ݒu��F���[�X������
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_LEASE_COMP;
    errorList
      = utils.checkIllegalString(
          errorList
         ,headerRow.getLeaseCompany()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  
  /*****************************************************************************
   * �_���̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param cntrctVo    �_���o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateCntrctCust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // �_���F�_��於
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,cntrctRow.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getPartyName()
         ,token1
         ,0
        );
    
    /////////////////////////////////////
    // �_���F�_��於�J�i
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME_ALT;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getPartyNameAlt()
         ,token1
         ,0
        );
    if ( ! isDoubleByteKana(
             txn
            ,cntrctRow.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00286
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTR_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
    
    /////////////////////////////////////
    // �_���F�X�֔ԍ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( cntrctRow.getPostalCodeFirst() == null             ||
           "".equals(cntrctRow.getPostalCodeFirst().trim())   ||
           cntrctRow.getPostalCodeSecond() == null            ||
           "".equals(cntrctRow.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,cntrctRow.getPostalCodeFirst()
              ,cntrctRow.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // �_���F�s���{��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getState()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �_���F�s�E��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getCity()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �_���F�Z��1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,cntrctRow.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getAddress1()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �_���F�Z��2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getAddress2()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // �_���F�d�b�ԍ�
    /////////////////////////////////////
    if ( ! utils.isTelNumber(cntrctRow.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // �_���F��\�Җ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_DELEGATE;
    errorList
      = utils.checkIllegalString(
          errorList
         ,cntrctRow.getRepresentativeName()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  
  /*****************************************************************************
   * VD���̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateVdInfo(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String newoldType = headerRow.getNewoldType();
    
    /////////////////////////////////////
    // VD���F�V�^��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_NEW_OLD;

    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,headerRow.getNewoldType()
           ,token1
           ,0
          );
    }

    /////////////////////////////////////
    // VD���F�Z����
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SELE_NUMBER;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getSeleNumber()
         ,token1
         ,0
         ,3
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // VD���F���[�J�[��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_MAKER_NAME;

    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,headerRow.getMakerCode()
           ,token1
           ,0
          );
    }

    /////////////////////////////////////
    // VD���F�K�i���^�O
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STD_TYPE;

    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,headerRow.getStandardType()
           ,token1
           ,0
          );
    }

    /////////////////////////////////////
    // VD���F�@��R�[�h
    /////////////////////////////////////
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.NEW_OLD_NEW.equals(newoldType) )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_VD_INFO_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_VENDOR_MODEL;
        errorList
          = utils.requiredCheck(
              errorList
             ,headerRow.getUnNumber()
             ,token1
             ,0
            );
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  
  /*****************************************************************************
   * ���̑������̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateOtherCondition(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String electricityType = headerRow.getElectricityType();

    /////////////////////////////////////
    // ���̑������F�_��N��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractYearDate()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // ���̑������F����ݒu���^��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallSupportAmt()
         ,token1
         ,0
         ,8
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // ���̑������F2��ڈȍ~�ݒu���^��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT2;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallSupportAmt2()
         ,token1
         ,0
         ,8
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // ���̑������F�x���T�C�N��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_PAYMENT_CYCLE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getPaymentCycle()
         ,token1
         ,0
         ,2
         ,true
         ,false
         ,false
         ,0
        );
    
    /////////////////////////////////////
    // ���̑������F�d�C��
    /////////////////////////////////////
    boolean requiredFlag = false;
    if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(electricityType) ||
         XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(electricityType)
       )
    {
      requiredFlag = true;
    }
    if ( ! submitFlag )
    {
      requiredFlag = false;
    }
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMOUNT;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getElectricityAmount()
         ,token1
         ,0
         ,5
         ,true
         ,false
         ,requiredFlag
         ,0
        );
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * ���̑������̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateConditionReason(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // ���̑������F���ʏ���
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_COND_REASON;
    errorList
      = utils.checkIllegalString(
          errorList
         ,headerRow.getConditionReason()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  
  /*****************************************************************************
   * BM1�̌���
   * @param txn           OADBTransaction�C���X�^���X
   * @param bm1Vo         BM1�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag    ��o�p�t���O
   * @return List         �G���[���X�g
   *****************************************************************************
   */
  public static List validateBm1Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String bmPaymentType = bm1Row.getBmPaymentType();
    String checkValue = null;
    /////////////////////////////////////
    // BM1�F���t�於
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm1Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getPartyName()
         ,token1
         ,0
        );
    
    /////////////////////////////////////
    // BM1�F���t�於�i�J�i�j
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getPartyNameAlt()
         ,token1
         ,0
        );
    if ( ! isDoubleByteKana(
             txn
            ,bm1Row.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00286
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
    
    /////////////////////////////////////
    // BM1�F�X�֔ԍ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm1Row.getPostalCodeFirst() == null             ||
           "".equals(bm1Row.getPostalCodeFirst().trim())   ||
           bm1Row.getPostalCodeSecond() == null            ||
           "".equals(bm1Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm1Row.getPostalCodeFirst()
              ,bm1Row.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // BM1�F�s���{��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getState()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM1�F�s�E��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getCity()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM1�F�Z��1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getAddress1()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM1�F�Z��2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm1Row.getAddress2()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM1�F�d�b�ԍ�
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm1Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM1�F�U���萔�����S
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm1Row.getTransferCommissionType()
           ,token1
           ,0
          );
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM2�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param bm2Vo       BM2�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateBm2Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String condBizType = headerRow.getConditionBusinessType();
    String regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
    }
    
    /////////////////////////////////////
    // BM2�F���t�於
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm2Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getPartyName()
         ,token1
         ,0
        );
    
    /////////////////////////////////////
    // BM2�F���t�於�i�J�i�j
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getPartyNameAlt()
         ,token1
         ,0
        );
    if ( ! isDoubleByteKana(
             txn
            ,bm2Row.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00286
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
    
    /////////////////////////////////////
    // BM2�F�X�֔ԍ�
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm2Row.getPostalCodeFirst() == null             ||
           "".equals(bm2Row.getPostalCodeFirst().trim())   ||
           bm2Row.getPostalCodeSecond() == null            ||
           "".equals(bm2Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm2Row.getPostalCodeFirst()
              ,bm2Row.getPostalCodeSecond()
             )
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,regionName
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // BM2�F�s���{��
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getState()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM2�F�s�E��
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getCity()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM2�F�Z��1
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getAddress1()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM2�F�Z��2
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm2Row.getAddress2()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM2�F�d�b�ԍ�
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm2Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,regionName
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM2�F�U���萔�����S
    /////////////////////////////////////
    token1 = regionName
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm2Row.getTransferCommissionType()
           ,token1
           ,0
          );
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM3�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm3Vo       BM3�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateBm3Cust(
    OADBTransaction                     txn
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // BM3�F���t�於
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME;
    if ( submitFlag )
    {
      errorList
        =  utils.requiredCheck(
              errorList
            ,bm3Row.getPartyName()
            ,token1
            ,0
           );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getPartyName()
         ,token1
         ,0
        );
    
    /////////////////////////////////////
    // BM3�F���t�於�i�J�i�j
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getPartyNameAlt()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getPartyNameAlt()
         ,token1
         ,0
        );
    if ( ! isDoubleByteKana(
             txn
            ,bm3Row.getPartyNameAlt()
           )
       )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00286
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM_PARTY_NAME_ALT
          );
      errorList.add(error);
    }
    
    /////////////////////////////////////
    // BM3�F�X�֔ԍ�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_POSTAL_CODE;
    if ( submitFlag )
    {
      if ( bm3Row.getPostalCodeFirst() == null             ||
           "".equals(bm3Row.getPostalCodeFirst().trim())   ||
           bm3Row.getPostalCodeSecond() == null            ||
           "".equals(bm3Row.getPostalCodeSecond().trim())
         )
      {
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00005
             ,XxcsoConstants.TOKEN_COLUMN
             ,token1
            );
        errorList.add(error);
      }

      if ( ! isPostalCode(
               txn
              ,bm3Row.getPostalCodeFirst()
              ,bm3Row.getPostalCodeSecond()
             )
         )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION;
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00287
             ,XxcsoConstants.TOKEN_REGION
             ,token1
            );
        errorList.add(error);
      }
    }

    /////////////////////////////////////
    // BM3�F�s���{��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_STATE;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getState()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getState()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM3�F�s�E��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CITY;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getCity()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getCity()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM3�F�Z��1
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS1;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getAddress1()
           ,token1
           ,0
          );
    }
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getAddress1()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM3�F�Z��2
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ADDRESS2;
    errorList
      = utils.checkIllegalString(
          errorList
         ,bm3Row.getAddress2()
         ,token1
         ,0
        );

    /////////////////////////////////////
    // BM3�F�d�b�ԍ�
    /////////////////////////////////////
    if ( ! utils.isTelNumber(bm3Row.getAddressLinesPhonetic()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00288
           ,XxcsoConstants.TOKEN_REGION
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
          );
      errorList.add(error);
    }

    /////////////////////////////////////
    // BM3�F�U���萔�����S
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_TRANSFER;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,bm3Row.getTransferCommissionType()
           ,token1
           ,0
          );
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * �_�񏑂ւ̋L�ڎ����̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateContractContent(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // �_�񏑂ւ̋L�ڎ����F���񎖍�
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_CNTRCT_CONTENT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_CONTENT;
    errorList
      = utils.checkIllegalString(
          errorList
         ,headerRow.getOtherContent()
         ,token1
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  

  /*****************************************************************************
   * �T�Z�N�ԑ��v�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateEstimateProfit(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // �������
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_COND_BIZ;
    if ( submitFlag )
    {
      errorList
        = utils.requiredCheck(
            errorList
           ,headerRow.getConditionBusinessType()
           ,token1
           ,0
          );
    }

    /////////////////////////////////////
    // ���̑������F�_��N��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRACT_YEAR;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getContractYearDate()
         ,token1
         ,0
         ,2
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // ���̑������F����ݒu���^��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_INST_SUP_AMT;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getInstallSupportAmt()
         ,token1
         ,0
         ,8
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // ���̑������F�d�C��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_OTHER_COND_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMOUNT;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getElectricityAmount()
         ,token1
         ,0
         ,5
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�F���Ԕ���
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getSalesMonth()
         ,token1
         ,0
         ,4
         ,true
         ,true
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�FBM��
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_BM_RATE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getBmRate()
         ,token1
         ,2
         ,2
         ,true
         ,false
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�F���[�X���i���z�j
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_LEASE_CHARGE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getLeaseChargeMonth()
         ,token1
         ,0
         ,2
         ,true
         ,false
         ,submitFlag
         ,0
        );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�F�H����
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_CONSTRUCT_CHARGE;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getConstructionCharge()
         ,token1
         ,0
         ,4
         ,true
         ,false
         ,false
         ,0
        );

    /////////////////////////////////////
    // �T�Z�N�ԑ��v�F�d�C��i���j
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_EST_PROFIT_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_ELECTRICITY_AMT_MONTH;
    errorList
      = utils.checkStringToNumber(
          errorList
         ,headerRow.getElectricityAmtMonth()
         ,token1
         ,2
         ,3
         ,true
         ,false
         ,false
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * �Y�t�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param attachVo    �Y�t�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateAttach(
    OADBTransaction                     txn
   ,XxcsoSpDecisionAttachFullVOImpl     attachVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // �Y�t�F�E�v
    /////////////////////////////////////
    token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_REGION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoSpDecisionConstants.TOKEN_VALUE_EXCERPT;

    int index = 0;
    while ( attachRow != null )
    {
      index++;
      
      errorList
        = utils.checkIllegalString(
            errorList
           ,attachRow.getExcerpt()
           ,token1
           ,index
          );

      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * �񑗐�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param scVo        �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo     �S�e��ꗥ�����o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo     �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param sendVo      �񑗐�o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateSend(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionScLineFullVOImpl     scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo
   ,XxcsoSpDecisionSendFullVOImpl       sendVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    String token1 = null;
    
    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    /////////////////////////////////////
    // ���كR�����g
    /////////////////////////////////////
    int index = 0;
    Number currentAuthLevel = null;
    
    while ( sendRow != null )
    {
      index++;

      if ( submitFlag )
      {
        token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_SEND_REGION
                + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                + XxcsoSpDecisionConstants.TOKEN_VALUE_EMPLOYEE_NUMBER;

        errorList
          = utils.requiredCheck(
              errorList
             ,sendRow.getApproveCode()
             ,token1
             ,index
            );
      }
      
      token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_SEND_REGION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoSpDecisionConstants.TOKEN_VALUE_COMMENT;

      errorList
        = utils.checkIllegalString(
            errorList
           ,sendRow.getApprovalComment()
           ,token1
           ,index
          );

      String approvalStateType = sendRow.getApprovalStateType();
      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
      {
        currentAuthLevel = sendRow.getApprAuthLevelNumber();
      }
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }

    if ( ! submitFlag )
    {
      return errorList;
    }

    OracleCallableStatement stmt = null;
    NUMBER lastApprAuthLevel = NUMBER.zero();
    StringBuffer sql = new StringBuffer(100);

    try
    {
      NUMBER returnValue = null;
      int checkValue = 0;
      
      /////////////////////////////////////
      // ���F�������x���ԍ��P
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_1(");
      sql.append("          :2, :3, :4, :5");
      sql.append("        );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
        
      String condBizType = headerRow.getConditionBusinessType();
      String allContainerType = headerRow.getAllContainerType();
      
      if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
           XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
         )
      {
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
        while ( scRow != null )
        {
          stmt.registerOutParameter(1, OracleTypes.NUMBER);
          stmt.setString(2, scRow.getFixedPrice());
          stmt.setString(3, scRow.getSalesPrice());
          stmt.setNull(4, OracleTypes.VARCHAR);
          stmt.setString(5, scRow.getBmConvRatePerSalesPrice());

          stmt.execute();

          returnValue = stmt.getNUMBER(1);
          XxcsoUtils.debug(
            txn, "return = " + returnValue.stringValue()
          );

          XxcsoUtils.debug(
            txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
          );

          checkValue = returnValue.compareTo(lastApprAuthLevel);
          XxcsoUtils.debug(
            txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
          );
          
          if ( checkValue > 0 )
          {
            lastApprAuthLevel = returnValue;
          }

          scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
        }
      }

      if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
           XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
         )
      {
        if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
        {
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
          while ( allCcRow != null )
          {
            String discountAmt = allCcRow.getDiscountAmt();
            if ( discountAmt == null || "".equals(discountAmt) )
            {
              allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
              continue;
            }

            stmt.registerOutParameter(1, OracleTypes.NUMBER);
            stmt.setNull(2, OracleTypes.VARCHAR);
            stmt.setNull(3, OracleTypes.VARCHAR);
            stmt.setString(4, allCcRow.getDiscountAmt());
            stmt.setString(5, allCcRow.getBmConvRatePerSalesPrice());

            stmt.execute();

            returnValue = stmt.getNUMBER(1);
            XxcsoUtils.debug(
              txn, "return = " + returnValue.stringValue()
            );

            XxcsoUtils.debug(
              txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
            );

            checkValue = returnValue.compareTo(lastApprAuthLevel);
            XxcsoUtils.debug(
              txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
            );
          
            if ( checkValue > 0 )
            {
              lastApprAuthLevel = returnValue;
            }

            allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
          }
        }
        else
        {
          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
          while ( selCcRow != null )
          {
            String discountAmt = selCcRow.getDiscountAmt();
            if ( discountAmt == null || "".equals(discountAmt) )
            {
              selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
              continue;
            }

            stmt.registerOutParameter(1, OracleTypes.NUMBER);
            stmt.setNull(2, OracleTypes.VARCHAR);
            stmt.setNull(3, OracleTypes.VARCHAR);
            stmt.setString(4, selCcRow.getDiscountAmt());
            stmt.setString(5, selCcRow.getBmConvRatePerSalesPrice());

            stmt.execute();

            returnValue = stmt.getNUMBER(1);
            XxcsoUtils.debug(
              txn, "return = " + returnValue.stringValue()
            );

            XxcsoUtils.debug(
              txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
            );

            checkValue = returnValue.compareTo(lastApprAuthLevel);
            XxcsoUtils.debug(
              txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
            );
          
            if ( checkValue > 0 )
            {
              lastApprAuthLevel = returnValue;
            }

            selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
          }
        }
      }

      if ( stmt != null )
      {
        stmt.close();
        stmt = null;
      }

      sql.delete(0, sql.length());

      /////////////////////////////////////
      // ���F�������x���ԍ��Q
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_2(:2);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getInstallSupportAmt());

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
      XxcsoUtils.debug(
        txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
      );
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
      }

      sql.delete(0, sql.length());

      /////////////////////////////////////
      // ���F�������x���ԍ��R
      /////////////////////////////////////
      String elecType = headerRow.getElectricityType();
      if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType)    ||
           XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(elecType)
         )
      {
        sql.append("BEGIN");
        sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_3(:2);");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.NUMBER);
        stmt.setString(2, headerRow.getElectricityAmount());

        stmt.execute();

        returnValue = stmt.getNUMBER(1);
        XxcsoUtils.debug(
          txn, "return = " + returnValue.stringValue()
        );

        XxcsoUtils.debug(
          txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
        );

        checkValue = returnValue.compareTo(lastApprAuthLevel);
        XxcsoUtils.debug(
          txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
        );
          
        if ( checkValue > 0 )
        {
          lastApprAuthLevel = returnValue;
        }

        if ( stmt != null )
        {
          stmt.close();
          stmt = null;
        }

        sql.delete(0, sql.length());
      }

      XxcsoUtils.debug(
        txn, "now authLevel = " + lastApprAuthLevel.stringValue()
      );

      /////////////////////////////////////
      // ���F�������x���ԍ��S
      /////////////////////////////////////
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_appr_auth_level_num_4(:2);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getConstructionCharge());

      stmt.execute();

      returnValue = stmt.getNUMBER(1);
      XxcsoUtils.debug(
        txn, "return = " + returnValue.stringValue()
      );

      XxcsoUtils.debug(
        txn, "lastApprAuthLevel = " + lastApprAuthLevel.stringValue()
      );

      checkValue = returnValue.compareTo(lastApprAuthLevel);
      XxcsoUtils.debug(
        txn, "return.comareTo(lastApprAuthLevel) = " + checkValue
      );
          
      if ( checkValue > 0 )
      {
        lastApprAuthLevel = returnValue;
      }

      if ( stmt != null )
      {
        stmt.close();
        stmt = null;
      }

      sql.delete(0, sql.length());
        
      if ( lastApprAuthLevel.compareTo(NUMBER.zero()) == 0 )
      {
        /////////////////////////////////////
        // ���F�������x���ԍ��i�f�t�H���g�j
        /////////////////////////////////////
        sql.append("BEGIN");
        sql.append("  xxcso_020001j_pkg.get_appr_auth_level_num_0(");
        sql.append("    on_appr_auth_level_num => :1");
        sql.append("   ,ov_errbuf              => :2");
        sql.append("   ,ov_retcode             => :3");
        sql.append("   ,ov_errmsg              => :4");
        sql.append("  );");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.NUMBER);
        stmt.registerOutParameter(2, OracleTypes.VARCHAR);
        stmt.registerOutParameter(3, OracleTypes.VARCHAR);
        stmt.registerOutParameter(4, OracleTypes.VARCHAR);

        stmt.execute();

        returnValue = stmt.getNUMBER(1);
        String errBuf  = stmt.getString(2);
        String retCode = stmt.getString(3);
        String errMsg  = stmt.getString(4);
        
        XxcsoUtils.debug(
          txn, "return  = " + returnValue.stringValue()
        );
        XxcsoUtils.debug(txn, "errBuf  = " + errBuf);
        XxcsoUtils.debug(txn, "retCode = " + retCode);
        XxcsoUtils.debug(txn, "errMsg   = " + errMsg);

        if ( ! "0".equals(retCode) )
        {
          OAException error = XxcsoMessage.createErrorMessage(retCode);
          errorList.add(error);
        }
        else
        {
          lastApprAuthLevel = returnValue;
        }
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_APPR_AUTH_LEVEL_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    XxcsoUtils.debug(
      txn, "last apprAuthLevel = " + lastApprAuthLevel.stringValue()
    );
    
    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    boolean checkFlag = false;
    boolean existFlag = false;
    String lastApprAuthName = null;
    
    while ( sendRow != null )
    {
      // ���F�������x�����擾����
      Number checkAuthNumber = sendRow.getApprAuthLevelNumber();
      XxcsoUtils.debug(
        txn, "checkAuthLevel = " + checkAuthNumber.stringValue()
      );
      
      if ( lastApprAuthLevel.compareTo(checkAuthNumber) == 0 )
      {
        // �ŏI���F���x�������擾����
        lastApprAuthName = sendRow.getApprovalAuthorityName();
        
        // ���F�������x��������p���F�������x���Ɠ������ꍇ�A
        // ��ƒ��̏��F�������x���Ɣ��肷��
        if ( currentAuthLevel != null )
        {
          // ����p���F�������x������ƒ��̏��F�������x�����
          // �������ꍇ�́A����p���F�������x������ƒ��̏��F�������x����
          // �ݒ肷��
          
          XxcsoUtils.debug(
            txn, "current authLevel = " + currentAuthLevel.stringValue()
          );

          int checkValue = lastApprAuthLevel.compareTo(currentAuthLevel);
          if ( checkValue < 0 )
          {
            lastApprAuthLevel = currentAuthLevel;
          }
        }

        // �ȍ~�ɗL���񑗐悪���邩�ǂ������`�F�b�N����
        checkFlag = true;
      }

      if ( ! checkFlag )
      {
        // �L���`�F�b�N�t���O�������Ă��Ȃ��ꍇ�́A���̃��R�[�h��
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // �񑗐�Ј��ԍ����擾����
      String approveCode = sendRow.getApproveCode();
      if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
      {
        // �񑗐悪�ȗ��̏ꍇ�́A���̃��R�[�h��
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // ��ƈ˗��敪���擾����
      String workRequestType = sendRow.getWorkRequestType();
      if ( XxcsoSpDecisionConstants.REQ_CONFIRM.equals(workRequestType) )
      {
        // �m�F�̏ꍇ�́A���̃��R�[�h��
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      // ���ׂẴ`�F�b�N��ʂ����ꍇ�̂݁A���݃t���O�𗧂Ă�
      existFlag = true;
      break;
    }

    if ( ! existFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00306
           ,XxcsoConstants.TOKEN_FORWARD
           ,lastApprAuthName
          );
      errorList.add(error);
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  

  /*****************************************************************************
   * �����ʏ����̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param scVo        �����ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateScLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionScLineFullVOImpl     scVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();
    List fixedPriceList = new ArrayList();
    List salesPriceList = new ArrayList();
    List repeatFixedPriceList = new ArrayList();
    List repeatSalesPriceList = new ArrayList();

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    /////////////////////////////////
    // ���l�E�K�{�`�F�b�N
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String fixedPrice = scRow.getFixedPrice();
      String salesPrice = scRow.getSalesPrice();
      String bm1BmRate  = scRow.getBm1BmRate();
      String bm1BmAmt   = scRow.getBm1BmAmount();
      String bm2BmRate  = scRow.getBm2BmRate();
      String bm2BmAmt   = scRow.getBm2BmAmount();
      String bm3BmRate  = scRow.getBm3BmRate();
      String bm3BmAmt   = scRow.getBm3BmAmount();

      errorList.addAll(
        validateFixedPrice(txn, fixedPrice, submitFlag, index)
      );
      errorList.addAll(
        validateSalesPrice(txn, salesPrice, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );

      if ( ! submitFlag )
      {
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
        continue;
      }
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
// �ۑ�ꗗNo.73�Ή� START
//        OAException error = null;
//        if ( contributeFlag )
//        {
//          error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00480
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//        }
//        else
//        {
//          error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00289
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//        }
//        
//        errorList.add(error);
// �ۑ�ꗗNo.73�Ή� END
      }
      else
      {
// �ۑ�ꗗNo.73�Ή� START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// �ۑ�ꗗNo.73�Ή� END
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( index == 0 )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00491
          );
      errorList.add(error);
    }
    
    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
    index = 0;

    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    /////////////////////////////////
    // �d���`�F�b�N
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String fixedPrice = scRow.getFixedPrice().replaceAll(",","");
      if ( fixedPriceList.contains(fixedPrice) )
      {
        if ( ! repeatFixedPriceList.contains(fixedPrice) )
        {
          repeatFixedPriceList.add(fixedPrice);
        }

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00425
             ,XxcsoConstants.TOKEN_PRICE
             ,fixedPrice
            );

        errorList.add(error);
      }
      else
      {
        fixedPriceList.add(fixedPrice);
      }
      
      String salesPrice = scRow.getSalesPrice().replaceAll(",","");
      if ( salesPriceList.contains(salesPrice) )
      {
        if ( ! repeatSalesPriceList.contains(salesPrice) )
        {
          repeatSalesPriceList.add(salesPrice);
        }

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00426
             ,XxcsoConstants.TOKEN_PRICE
             ,salesPrice
            );

        errorList.add(error);
      }
      else
      {
        salesPriceList.add(salesPrice);
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    index = 0;

    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    /////////////////////////////////
    // ���v�l�`�F�b�N
    /////////////////////////////////
    while ( scRow != null )
    {
      index++;
      String salesPrice = scRow.getSalesPrice();
      String bm1BmRate  = scRow.getBm1BmRate();
      String bm1BmAmt   = scRow.getBm1BmAmount();
      String bm2BmRate  = scRow.getBm2BmRate();
      String bm2BmAmt   = scRow.getBm2BmAmount();
      String bm3BmRate  = scRow.getBm3BmRate();
      String bm3BmAmt   = scRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00481
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00291
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }

      if ( ! isLimitTotalValue(
               bm1BmAmt
              ,bm2BmAmt
              ,bm3BmAmt
              ,salesPrice
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00482
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00292
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * �S�e��ꗥ�����̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param allCcVo     �S�e��ꗥ�����o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateAllCcLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    int nullLineCount = 0;
    
    /////////////////////////////////
    // ���l�E�K�{�`�F�b�N
    /////////////////////////////////
    while ( allCcRow != null )
    {
      index++;
      String discountAmt = allCcRow.getDiscountAmt();
      String bm1BmRate = allCcRow.getBm1BmRate();
      String bm1BmAmt  = allCcRow.getBm1BmAmount();
      String bm2BmRate = allCcRow.getBm2BmRate();
      String bm2BmAmt  = allCcRow.getBm2BmAmount();
      String bm3BmRate = allCcRow.getBm3BmRate();
      String bm3BmAmt  = allCcRow.getBm3BmAmount();

      errorList.addAll(
        validateDiscountAmt(txn, discountAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );

      if ( ! submitFlag )
      {
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
        continue;
      }
      
// �ۑ�ꗗNo.73�Ή� START
//      if ( (bm1BmRate   == null || "".equals(bm1BmRate.trim()))   &&
//           (bm2BmRate   == null || "".equals(bm2BmRate.trim()))   &&
//           (bm3BmRate   == null || "".equals(bm3BmRate.trim()))   &&
//           (bm1BmAmt    == null || "".equals(bm1BmAmt.trim()))    &&
//           (bm2BmAmt    == null || "".equals(bm2BmAmt.trim()))    &&
//           (bm3BmAmt    == null || "".equals(bm3BmAmt.trim()))    &&
//           (discountAmt == null || "".equals(discountAmt.trim()))
//         )
//      {
//        nullLineCount++;
//      }
// �ۑ�ꗗNo.73�Ή� END
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
        if ( discountAmt != null && ! "".equals(discountAmt) )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00483
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00294
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      else
      {
// �ۑ�ꗗNo.73�Ή� START
//        if ( discountAmt == null || "".equals(discountAmt.trim()) )
//        {
//          OAException error = null;
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00484
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00295
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//
//          errorList.add(error);
//        }
// �ۑ�ꗗNo.73�Ή� END

// �ۑ�ꗗNo.73�Ή� START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// �ۑ�ꗗNo.73�Ή� END
      }

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
// �ۑ�ꗗNo.73�Ή� START
//    if ( allCcVo.getRowCount() == nullLineCount )
//    {
//      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00293);
//    }
// �ۑ�ꗗNo.73�Ή� END
    
    index = 0;

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();

    /////////////////////////////////
    // ���v�l�`�F�b�N
    /////////////////////////////////
    while ( allCcRow != null )
    {
      index++;
      String discountAmt = allCcRow.getDiscountAmt();
      Number fixedPrice  = allCcRow.getDefinedFixedPrice();
      String bm1BmRate   = allCcRow.getBm1BmRate();
      String bm1BmAmt    = allCcRow.getBm1BmAmount();
      String bm2BmRate   = allCcRow.getBm2BmRate();
      String bm2BmAmt    = allCcRow.getBm2BmAmount();
      String bm3BmRate   = allCcRow.getBm3BmRate();
      String bm3BmAmt    = allCcRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00485
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00298
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }

        errorList.add(error);
      }

      double discountAmtDoubleValue = (double)0;

      if ( discountAmt != null && ! "".equals(discountAmt) )
      {
        discountAmtDoubleValue
          = Double.parseDouble(discountAmt.replaceFirst(",",""));
      }

      double limitValue = discountAmtDoubleValue + fixedPrice.doubleValue();
      if ( limitValue <= (double)0 )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00530
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          )
        );
      }
      else
      {
        if ( ! isLimitTotalValue(
                 bm1BmAmt
                ,bm2BmAmt
                ,bm3BmAmt
                ,String.valueOf(limitValue)
               )
           )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00486
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00299
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      
      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * �e��ʏ����̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param headerVo    SP�ꌈ�w�b�_�o�^�^�X�V�p�r���[�C���X�^���X
   * @param selCcVo     �e��ʏ����o�^�^�X�V�p�r���[�C���X�^���X
   * @param submitFlag  ��o�p�t���O
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  public static List validateSelCcLine(
    OADBTransaction                     txn
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo
   ,boolean                             submitFlag
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    /////////////////////////////////////
    // �e�s���擾
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    int index = 0;
    String condBizType = headerRow.getConditionBusinessType();
    boolean contributeFlag = false;
    
    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      contributeFlag = true;
    }

    int nullLineCount = 0;
    
    /////////////////////////////////
    // ���l�E�K�{�`�F�b�N
    /////////////////////////////////
    while ( selCcRow != null )
    {
      index++;
      String discountAmt = selCcRow.getDiscountAmt();
      String bm1BmRate = selCcRow.getBm1BmRate();
      String bm1BmAmt  = selCcRow.getBm1BmAmount();
      String bm2BmRate = selCcRow.getBm2BmRate();
      String bm2BmAmt  = selCcRow.getBm2BmAmount();
      String bm3BmRate = selCcRow.getBm3BmRate();
      String bm3BmAmt  = selCcRow.getBm3BmAmount();

      errorList.addAll(
        validateDiscountAmt(txn, discountAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmRate(txn, bm1BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm1BmAmt(txn, bm1BmAmt, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmRate(txn, bm2BmRate, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm2BmAmt(txn, bm2BmAmt, contributeFlag, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmRate(txn, bm3BmRate, submitFlag, index)
      );
      errorList.addAll(
        validateBm3BmAmt(txn, bm3BmAmt, submitFlag, index)
      );

      if ( ! submitFlag )
      {
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
        continue;
      }
      
// �ۑ�ꗗNo.73�Ή� START
//      if ( (bm1BmRate   == null || "".equals(bm1BmRate.trim()))   &&
//           (bm2BmRate   == null || "".equals(bm2BmRate.trim()))   &&
//           (bm3BmRate   == null || "".equals(bm3BmRate.trim()))   &&
//           (bm1BmAmt    == null || "".equals(bm1BmAmt.trim()))    &&
//           (bm2BmAmt    == null || "".equals(bm2BmAmt.trim()))    &&
//           (bm3BmAmt    == null || "".equals(bm3BmAmt.trim()))    &&
//           (discountAmt == null || "".equals(discountAmt.trim()))
//         )
//      {
//        nullLineCount++;
//      }
// �ۑ�ꗗNo.73�Ή� END
      
      if ( (bm1BmRate == null || "".equals(bm1BmRate.trim())) &&
           (bm2BmRate == null || "".equals(bm2BmRate.trim())) &&
           (bm3BmRate == null || "".equals(bm3BmRate.trim())) &&
           (bm1BmAmt  == null || "".equals(bm1BmAmt.trim()))  &&
           (bm2BmAmt  == null || "".equals(bm2BmAmt.trim()))  &&
           (bm3BmAmt  == null || "".equals(bm3BmAmt.trim()))
         )
      {
        if ( discountAmt != null && ! "".equals(discountAmt) )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00483
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00294
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }

          errorList.add(error);
        }
      }
      else
      {
// �ۑ�ꗗNo.73�Ή� START
//        if ( discountAmt == null || "".equals(discountAmt.trim()) )
//        {
//          OAException error = null;
//          
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00484
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00295
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//
//          errorList.add(error);
//        }
// �ۑ�ꗗNo.73�Ή� END

// �ۑ�ꗗNo.73�Ή� START
//        if ( bm1BmRate != null      &&
//             ! "".equals(bm1BmRate) &&
//             bm1BmAmt  != null      &&
//             ! "".equals(bm1BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//
//        if ( bm2BmRate != null      &&
//             ! "".equals(bm2BmRate) &&
//             bm2BmAmt  != null      &&
//             ! "".equals(bm2BmAmt)
//           )
//        {
//          OAException error = null;
//
//          if ( contributeFlag )
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          else
//          {
//            error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00489
//                 ,XxcsoConstants.TOKEN_REGION
//                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
//                 ,XxcsoConstants.TOKEN_INDEX
//                 ,String.valueOf(index)
//                );
//          }
//          errorList.add(error);
//        }
//
//        if ( bm3BmRate != null      &&
//             ! "".equals(bm3BmRate) &&
//             bm3BmAmt  != null      &&
//             ! "".equals(bm3BmAmt)
//           )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00489
//               ,XxcsoConstants.TOKEN_REGION
//               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
//               ,XxcsoConstants.TOKEN_INDEX
//               ,String.valueOf(index)
//              );
//          errorList.add(error);
//        }

        if ( isBothBmValue(txn, bm1BmRate, bm1BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm2BmRate, bm2BmAmt) )
        {
          OAException error = null;

          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00489
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }

        if ( isBothBmValue(txn, bm3BmRate, bm3BmAmt) )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00489
               ,XxcsoConstants.TOKEN_REGION
               ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
          errorList.add(error);
        }
// �ۑ�ꗗNo.73�Ή� END
      }
      
      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    if ( ! submitFlag )
    {
      return errorList;
    }
    
    if ( selCcVo.getRowCount() == nullLineCount )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00293);
    }
    
    index = 0;

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    /////////////////////////////////
    // ���v�l�`�F�b�N
    /////////////////////////////////
    while ( selCcRow != null )
    {
      index++;
      String discountAmt = selCcRow.getDiscountAmt();
      Number fixedPrice  = selCcRow.getDefinedFixedPrice();
      String bm1BmRate   = selCcRow.getBm1BmRate();
      String bm1BmAmt    = selCcRow.getBm1BmAmount();
      String bm2BmRate   = selCcRow.getBm2BmRate();
      String bm2BmAmt    = selCcRow.getBm2BmAmount();
      String bm3BmRate   = selCcRow.getBm3BmRate();
      String bm3BmAmt    = selCcRow.getBm3BmAmount();

      if ( ! isLimitTotalValue(
               bm1BmRate
              ,bm2BmRate
              ,bm3BmRate
              ,String.valueOf(100)
             )
         )
      {
        OAException error = null;
        if ( contributeFlag )
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00485
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        else
        {
          error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00298
               ,XxcsoConstants.TOKEN_INDEX
               ,String.valueOf(index)
              );
        }
        
        errorList.add(error);
      }

      double discountAmtDoubleValue = (double)0;

      if ( discountAmt != null && ! "".equals(discountAmt) )
      {
        discountAmtDoubleValue
          = Double.parseDouble(discountAmt.replaceAll(",",""));
      }

      double limitValue = discountAmtDoubleValue + fixedPrice.doubleValue();
      if ( limitValue <= (double)0 )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00530
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          )
        );
      }
      else
      {
        if ( ! isLimitTotalValue(
                 bm1BmAmt
                ,bm2BmAmt
                ,bm3BmAmt
                ,String.valueOf(limitValue)
               )
           )
        {
          OAException error = null;
          if ( contributeFlag )
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00486
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          else
          {
            error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00299
                 ,XxcsoConstants.TOKEN_PRICE
                 ,String.valueOf((int)limitValue)
                 ,XxcsoConstants.TOKEN_INDEX
                 ,String.valueOf(index)
                );
          }
          errorList.add(error);
        }
      }
      
      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


// �ۑ�ꗗNo.73�Ή� START
  /*****************************************************************************
   * BM���^BM���z�������̓`�F�b�N
   * @param txn                 OADBTransaction�C���X�^���X
   * @param bmRate              BM���̒l
   * @param bmAmount            BM���z�̒l
   * @return boolean            ���� true  : �����Ƃ����͂���Ă���
   *                                 false : �Е��������͂Ƃ��ɓ��͂���Ă��Ȃ�
   *****************************************************************************
   */
  public static boolean isBothBmValue(
    OADBTransaction    txn
   ,String             bmRate
   ,String             bmAmount
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    double bmRateDouble   = 0;
    double bmAmountDouble = 0;

    if ( bmRate == null || "".equals(bmRate) )
    {
      return false;
    }

    if ( bmAmount == null || "".equals(bmAmount) )
    {
      return false;
    }
    
    try
    {
      bmRateDouble   = Double.parseDouble(bmRate);
      bmAmountDouble = Double.parseDouble(bmAmount);
    }
    catch ( NumberFormatException nfe )
    {
      return false;
    }

    if ( bmRateDouble   != (double)0 &&
         bmAmountDouble != (double)0
       )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }


  /*****************************************************************************
   * BM���̓`�F�b�N
   * @param txn                 OADBTransaction�C���X�^���X
   * @param bmRate              BM���̒l
   * @param bmAmount            BM���z�̒l
   * @return boolean            ���� true  : ���͂���Ă���
   *                                 false : ���͂���Ă��Ȃ�
   *****************************************************************************
   */
  public static boolean isBmInput(
    OADBTransaction    txn
   ,String             bmRate
   ,String             bmAmount
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    double bmRateDouble   = 0;
    double bmAmountDouble = 0;

    if ( bmRate != null && ! "".equals(bmRate) )
    {
      bmRateDouble   = Double.parseDouble(bmRate);
    }

    if ( bmAmount != null && ! "".equals(bmAmount) )
    {
      bmAmountDouble = Double.parseDouble(bmAmount);
    }
    
    if ( bmRateDouble != (double)0 || bmAmountDouble != (double)0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
// �ۑ�ꗗNo.73�Ή� END


  /*****************************************************************************
   * �艿�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param fixedPrice  �艿
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateFixedPrice(
    OADBTransaction     txn
   ,String              fixedPrice
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,fixedPrice
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_FIXED_PRICE
         ,0
         ,4
         ,submitFlag
         ,false
         ,submitFlag
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * �����̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param salesPrice  ����
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateSalesPrice(
    OADBTransaction     txn
   ,String              salesPrice
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,salesPrice
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_PRICE
         ,0
         ,4
         ,submitFlag
         ,submitFlag
         ,submitFlag
         ,index
        );

    double doubleValue = 0;
    boolean unitErrorFlag = false;

    if ( salesPrice != null               &&
         ! "".equals(salesPrice.trim())   &&
         ! "0".equals(salesPrice.trim())
       )
    {
      try
      {
        doubleValue = Double.parseDouble(salesPrice.replaceAll(",",""));
      }
      catch ( NumberFormatException nfe )
      {
        unitErrorFlag = true;
      }

      if ( (doubleValue % (double)10) != (double)0 )
      {
        unitErrorFlag = true;
      }
    }
    else
    {
      unitErrorFlag = true;
    }

    if ( submitFlag && unitErrorFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00300
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_PRICE
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          );

      errorList.add(error);
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * �艿����̒l���z�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param discountAmt �艿����̒l���z
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateDiscountAmt(
    OADBTransaction     txn
   ,String              discountAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,discountAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_DISCOUNT_AMT
         ,0
         ,4
         ,false
         ,false
         ,submitFlag
         ,index
        );

    double doubleValue = 0;
    boolean unitErrorFlag = false;

    if ( discountAmt != null               &&
         ! "".equals(discountAmt.trim())   &&
         ! "0".equals(discountAmt.trim())
       )
    {
      try
      {
        doubleValue = Double.parseDouble(discountAmt.replaceAll(",",""));
      }
      catch ( NumberFormatException nfe )
      {
        unitErrorFlag = true;
      }

      if ( (doubleValue % (double)10) != (double)0 )
      {
        unitErrorFlag = true;
      }
    }

    if ( submitFlag && unitErrorFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00300
           ,XxcsoConstants.TOKEN_COLUMN
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_DISCOUNT_AMT
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          );

      errorList.add(error);
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM1BM���̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm1BmRate   BM1BM��
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm1BmRate(
    OADBTransaction     txn
   ,String              bm1BmRate
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm1BmRate
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_BM_RATE
         ,2
         ,2
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM2BM���̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm2BmRate   BM2BM��
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm2BmRate(
    OADBTransaction     txn
   ,String              bm2BmRate
   ,boolean             contributeFlag
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String token = null;

    if ( contributeFlag )
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_BM_RATE;
    }
    else
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_BM_RATE;
    }
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm2BmRate
         ,token
         ,2
         ,2
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM3BM���̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm3BmRate   BM3BM��
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm3BmRate(
    OADBTransaction     txn
   ,String              bm3BmRate
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm3BmRate
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_BM_RATE
         ,2
         ,2
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }



  /*****************************************************************************
   * BM1BM���z�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm1BmAmt    BM1BM���z
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm1BmAmt(
    OADBTransaction     txn
   ,String              bm1BmAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm1BmAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_BM_AMT
         ,2
         ,3
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM2BM���z�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm2BmAmt    BM2BM���z
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm2BmAmt(
    OADBTransaction     txn
   ,String              bm2BmAmt
   ,boolean             contributeFlag
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    String token = null;
    
    if ( contributeFlag )
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_BM_AMT;
    }
    else
    {
      token = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_BM_AMT;
    }
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm2BmAmt
         ,token
         ,2
         ,3
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * BM3BM���z�̌���
   * @param txn         OADBTransaction�C���X�^���X
   * @param bm3BmAmt    BM3BM���z
   * @param submitFlag  ��o�p�t���O
   * @param index       �s�ԍ�
   * @return List       �G���[���X�g
   *****************************************************************************
   */
  private static List validateBm3BmAmt(
    OADBTransaction     txn
   ,String              bm3BmAmt
   ,boolean             submitFlag
   ,int                 index
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();

    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);
    
    errorList
      = utils.checkStringToNumber(
          errorList
         ,bm3BmAmt
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_BM_AMT
         ,2
         ,3
         ,submitFlag
// �ۑ�ꗗNo.73�Ή� START
//         ,submitFlag
         ,false
// �ۑ�ꗗNo.73�Ή� END
         ,false
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /*****************************************************************************
   * ���v�l�̌���
   * @param bm1Value    BM1���^BM1���z�̒l
   * @param bm2Value    BM2���^BM2���z�̒l
   * @param bm3Value    BM3���^BM3���z�̒l
   * @param maxValue    �ő�l
   * @return boolean    ���،���
   *****************************************************************************
   */
  private static boolean isLimitTotalValue(
    String   bm1Value
   ,String   bm2Value
   ,String   bm3Value
   ,String   maxValue
  )
  {
    double bm1DoubleValue = (double)0;
    double bm2DoubleValue = (double)0;
    double bm3DoubleValue = (double)0;
    double maxDoubleValue = (double)0;
    boolean returnValue   = true;
    
    if ( bm1Value != null && ! "".equals(bm1Value.replaceAll(",","")) )
    {
      bm1DoubleValue = Double.parseDouble(bm1Value.replaceAll(",",""));
    }

    if ( bm2Value != null && ! "".equals(bm2Value.replaceAll(",","")) )
    {
      bm2DoubleValue = Double.parseDouble(bm2Value.replaceAll(",",""));
    }

    if ( bm3Value != null && ! "".equals(bm3Value.replaceAll(",","")) )
    {
      bm3DoubleValue = Double.parseDouble(bm3Value.replaceAll(",",""));
    }

    if ( maxValue != null && ! "".equals(maxValue.replaceAll(",","")) )
    {
      maxDoubleValue = Double.parseDouble(maxValue.replaceAll(",",""));
    }

    if ( (bm1DoubleValue + bm2DoubleValue + bm3DoubleValue) > maxDoubleValue )
    {
      returnValue = false;
    }

    return returnValue;
  }


  /*****************************************************************************
   * �X�֔ԍ��̌���
   * @param txn                 OADBTransaction�C���X�^���X
   * @param postalCodeFirst     �X�֔ԍ��i�O���j
   * @param postalCodeSecond    �X�֔ԍ��i����j
   * @return boolean            ���،���
   *****************************************************************************
   */
  private static boolean isPostalCode(
    OADBTransaction  txn
   ,String           postalCodeFirst
   ,String           postalCodeSecond
  )
  {
    boolean returnValue = true;
    List errorList = new ArrayList();
    
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    errorList = 
      utils.checkStringToNumber(
        errorList
       ,postalCodeFirst
       ,"dummy"
       ,4
       ,4
       ,true
       ,true
       ,false
       ,0
      );

    if ( errorList.size() > 0 )
    {
      returnValue = false;
    }
    else
    {
      if ( postalCodeFirst == null )
      {
        returnValue = false;
      }
      else
      {
        if ( postalCodeFirst.length() != 3 )
        {
          returnValue = false;
        }
      }
    }

    errorList =
      utils.checkStringToNumber(
        errorList
       ,postalCodeSecond
       ,"dummy"
       ,5
       ,5
       ,true
       ,true
       ,false
       ,0
      );

    if ( errorList.size() > 0 )
    {
      returnValue = false;
    }
    else
    {
      if ( postalCodeSecond == null )
      {
        returnValue = false;
      }
      else
      {
        if ( postalCodeSecond.length() != 4 )
        {
          returnValue = false;
        }
      }
    }

    return returnValue;
  }


  /*****************************************************************************
   * �S�p�J�i�̌���
   * @param txn                 OADBTransaction�C���X�^���X
   * @param value               �`�F�b�N�Ώۂ̒l
   * @return boolean            ���،���
   *****************************************************************************
   */
  private static boolean isDoubleByteKana(
    OADBTransaction   txn
   ,String            value
  )
  {
    OracleCallableStatement stmt = null;
    boolean returnValue = true;

    if ( value == null || "".equals(value.trim()) )
    {
      return true;
    }
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.chk_double_byte_kana(:2);");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setString(2, value);

      stmt.execute();

      String returnString = stmt.getString(1);
      if ( ! "1".equals(returnString) )
      {
        returnValue = false;
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_DOUBLE_BYTE_KANA_CHK
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    return returnValue;
  }
}