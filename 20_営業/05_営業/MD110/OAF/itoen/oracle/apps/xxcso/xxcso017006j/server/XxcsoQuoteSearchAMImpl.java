/*============================================================================
* �t�@�C���� : XxcsoQuoteSearchAMImpl
* �T�v����   : ���ό����A�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS���g      �V�K�쐬
* 2012-09-10 1.1  SCSK�s�G��  �yE_�{�ғ�_09945�z���Ϗ��̏Ɖ���@�̕ύX�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.server;

import itoen.oracle.apps.xxcso.xxcso017006j.util.XxcsoQuoteSearchConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * ���ς��������邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS���g
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoQuoteSearchAMImpl extends OAApplicationModuleImpl 
{
 
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSearchAMImpl()
  {
  }
  
  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @throw OAException
   *****************************************************************************
   */
  public void initDetails()
  {
    //����������
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteSearchTermsVOImpl");
    }
    // ����ʂ���̑J�ڍl��
    if ( !termsVo.isPreparedForExecution() )
    {
      // �������������s
      termsVo.executeQuery();
    }

    XxcsoLookupListVOImpl quoteTypeListVo = getXxcsoQuoteTypeListVO();
    if ( quoteTypeListVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteTypeListVO");
    }
    
    // ���ώ�ʎ擾
    quoteTypeListVo.initQuery(
      "XXCSO1_QUOTE_TYPE"
     ,"lookup_code"
    );
  }

  /*****************************************************************************
   * �i�ރ{�^�������������ۂ̏����ł��B
   * @return HashMap
   * @throw  OAException
   *****************************************************************************
   */
  // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod Start
  //public HashMap executeSearch()
    public HashMap executeSearch(String searchStandard)
  // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod End
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[executeSearch]");

    HashMap retMap = new HashMap();

    // ���������擾
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVOImpl");
    }

    XxcsoQuoteSearchTermsVORowImpl paramRow
      = (XxcsoQuoteSearchTermsVORowImpl)termsVo.first();
    if ( paramRow == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVORowImpl");
    }

    XxcsoUtils.debug(txn, "QuoteType : " + paramRow.getQuoteType());
    XxcsoUtils.debug(txn, "QuoteNumber : " + paramRow.getQuoteNumber());
    XxcsoUtils.debug(txn, "QuoteRevisionNumber : " + paramRow.getQuoteRevisionNumber());

    // ���̓p�����[�^�`�F�b�N
    List errorList = this.paramCheck(paramRow);
    // �G���[������ꍇ
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // �ł����͂���Ă���ꍇ
    if ( (paramRow.getQuoteRevisionNumber() != null) 
           && (!"".equals(paramRow.getQuoteRevisionNumber())) )
    {
      XxcsoQuoteSearch1VOImpl searchVo1 = getXxcsoQuoteSearch1VO1();
      if ( searchVo1 == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSearch1VOImpl");
      }
      
      XxcsoUtils.debug(txn, "[�ł����͂���Ă���]");
      
      // �������s
      searchVo1.initQuery(
        paramRow.getQuoteType(),
        paramRow.getQuoteNumber(),
        String.valueOf(Integer.parseInt(paramRow.getQuoteRevisionNumber()))
      );

      // �����`�F�b�N(first��null�`�F�b�N)
      XxcsoQuoteSearch1VORowImpl searchRow1
        = (XxcsoQuoteSearch1VORowImpl)searchVo1.first();

      // �������ʂ��Ȃ��ꍇ
      if (searchRow1 == null) 
      {
        throw XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00466
             ,XxcsoConstants.TOKEN_QUOTE_NUMBER
             ,paramRow.getQuoteNumber()
             ,XxcsoConstants.TOKEN_QUOTE_R_N
             ,paramRow.getQuoteRevisionNumber()
            );
      }

      // ���σw�b�_�[ID
      retMap.put(
        XxcsoConstants.TRANSACTION_KEY1,
        searchRow1.getQuoteHeaderId()
      );
      // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod Start
      // ���s�敪
      //retMap.put(
      //    XxcsoConstants.EXECUTE_MODE,
      //    XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
      //);
      //��L�擾�����v���t�@�C���l��3�̏ꍇ�A���s�敪��READ_ONLY��ݒ�
      //��L�擾�����v���t�@�C���l��3�ȊO�̏ꍇ�A���s�敪��UPDATE��ݒ�
      // ���s�敪
      if ( null != searchStandard && 
           !"".equals(searchStandard) && 
           searchStandard.equals(
           XxcsoQuoteSearchConstants.XXCSO1_QUOTE_STANDARD_VALUE_3))
      {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_READ_ONLY
        );
      } else {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
        );
      }
      // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod End
    }
    else
    {
      XxcsoQuoteSearch2VOImpl searchVo2 = getXxcsoQuoteSearch2VO1();
      if ( searchVo2 == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSearch2VOImpl");
      }
      
       XxcsoUtils.debug(txn, "[�ł�������]");
       
      // �������s
     searchVo2.initQuery(
        paramRow.getQuoteType(),
        paramRow.getQuoteNumber()
      );
      
      // �����`�F�b�N(first��null�`�F�b�N)
      XxcsoQuoteSearch2VORowImpl searchRow2
        = (XxcsoQuoteSearch2VORowImpl)searchVo2.first();

      // �������ʂ��Ȃ��ꍇ
      if (searchRow2 == null) 
      {
        throw XxcsoMessage.createErrorMessage(
              "APP-XXCSO1-00466"
             ,"QUOTE_NUMBER"
             ,paramRow.getQuoteNumber()
             ,"QUOTE_REVISION_NUMBER"
             ,paramRow.getQuoteRevisionNumber()
            );
      }
      
      // ���σw�b�_�[ID
      retMap.put(
        XxcsoConstants.TRANSACTION_KEY1,
        searchRow2.getQuoteHeaderId()
      );
      // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod Start
      // ���s�敪
      //retMap.put(
      //  XxcsoConstants.EXECUTE_MODE,
      //  XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
      //);
      //��L�擾�����v���t�@�C���l��3�̏ꍇ�A���s�敪��READ_ONLY��ݒ�
      //��L�擾�����v���t�@�C���l��3�ȊO�̏ꍇ�A���s�敪��UPDATE��ݒ�
      if ( null != searchStandard && 
           !"".equals(searchStandard) &&
           searchStandard.equals(
           XxcsoQuoteSearchConstants.XXCSO1_QUOTE_STANDARD_VALUE_3))
      {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_READ_ONLY
        );
      } else {
        retMap.put(
          XxcsoConstants.EXECUTE_MODE,
          XxcsoQuoteSearchConstants.EXECUTE_MODE_UPDATE
        );      
      }
      // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod End
    }

    return retMap;
  }

  /*****************************************************************************
   * �����{�^�������������ۂ̏����ł��B
   * @throw OAException
   *****************************************************************************
   */
  public void ClearBtn()
  {
    // ��������������
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteSearchTermsVOImpl");
    }
    termsVo.executeQuery();
  }

  /*****************************************************************************
   * ���ώ�ʂ�Ԃ��B
   * @return quoteType;
   * @throw OAException
   *****************************************************************************
   */
  public String getQuoteType()
  {
    // ���ώ�ʎ擾
    XxcsoQuoteSearchTermsVOImpl termsVo = getXxcsoQuoteSearchTermsVO1();
    if ( termsVo == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVOImpl");
    }

    XxcsoQuoteSearchTermsVORowImpl paramRow
      = (XxcsoQuoteSearchTermsVORowImpl)termsVo.first();
    if ( paramRow == null )
    {
      throw XxcsoMessage.createInstanceLostError
        ("XxcsoQuoteSearchTermsVORowImpl");
    }

    return paramRow.getQuoteType();
  }

  /*****************************************************************************
   * �����p�����[�^�G���[�`�F�b�N�����ł��B
   * @return List errorList
   * @throw  OAException
   *****************************************************************************
   */
  private List paramCheck(XxcsoQuoteSearchTermsVORowImpl paramRow)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[paramCheck]");

    // ���̓`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    
    List errorList = new ArrayList();

    // ���ώ�ʂ̕K�{�`�F�b�N
    errorList
      = util.requiredCheck(
          errorList
         ,paramRow.getQuoteType()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_TYPE
         ,0
        );
        
    // ���ϔԍ��̕K�{�`�F�b�N
    errorList
      = util.requiredCheck(
          errorList
         ,paramRow.getQuoteNumber()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_NUMBER
         ,0
        );
        
    // �ł̐��l�`�F�b�N
    errorList
      = util.checkStringToNumber(
          errorList
         ,paramRow.getQuoteRevisionNumber()
         ,XxcsoQuoteSearchConstants.TOKEN_VALUE_QUOTE_REVISION_NUMBER
         ,0
         ,2
         ,true
         ,true
         ,false
         ,0
        );    

    return errorList;    
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017006j.server", "XxcsoQuoteSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearch1VO1
   */
  public XxcsoQuoteSearch1VOImpl getXxcsoQuoteSearch1VO1()
  {
    return (XxcsoQuoteSearch1VOImpl)findViewObject("XxcsoQuoteSearch1VO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearch2VO1
   */
  public XxcsoQuoteSearch2VOImpl getXxcsoQuoteSearch2VO1()
  {
    return (XxcsoQuoteSearch2VOImpl)findViewObject("XxcsoQuoteSearch2VO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteSearchTermsVO1
   */
  public XxcsoQuoteSearchTermsVOImpl getXxcsoQuoteSearchTermsVO1()
  {
    return (XxcsoQuoteSearchTermsVOImpl)findViewObject("XxcsoQuoteSearchTermsVO1");
  }
}