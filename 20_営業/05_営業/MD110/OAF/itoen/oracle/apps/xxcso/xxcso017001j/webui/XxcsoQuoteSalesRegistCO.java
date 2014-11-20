/*============================================================================
* �t�@�C���� : XxcsoQuoteSalesRegistCO
* �T�v����   : �̔���p���ϓ��͉�ʃR���g���[���N���X
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-02 1.0  SCS�y���    �V�K�쐬
* 2012-09-10 1.1  SCSK�s�G��  �yE_�{�ғ�_09945�z���Ϗ��̏Ɖ���@�̕ύX�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.OADialogPage;
import itoen.oracle.apps.xxcso.xxcso017001j.util.XxcsoQuoteConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;
import oracle.cabo.ui.beans.form.TextInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OAMultipleSelectionBean;
/*******************************************************************************
 * �̔���p���ϓ��͉�ʂ̃R���g���[���N���X
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSalesRegistCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN��������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    boolean errorMode = false;
    super.processRequest(pageContext, webBean);

    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // URL����p�����[�^���擾���܂��B
    String quoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String tranDiv = 
      pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // AM�֓n���������쐬���܂��B
    Serializable[] params = {
      quoteHeaderId
    };

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    // �������ɐݒ肵�����\�b�h���̃��\�b�h��Call���܂��B
    Boolean returnValue = Boolean.TRUE;
    // ***���s�敪�F�R�s�[
    if ( XxcsoQuoteConstants.TRANDIV_COPY.equals(tranDiv) )
    {
      am.invokeMethod("initDetailsCopy", params);
    }
    // ***���s�敪�F�ł̉���
    else if ( XxcsoQuoteConstants.TRANDIV_REVISION_UP.equals(tranDiv) )
    {
      am.invokeMethod("initDetailsRevisionUp", params);
    }
    // ***���s�敪�F���ό�����ʁ^���j���[����J��
    else
    {
      am.invokeMethod("initDetails", params);      
    }

    // �|�b�v���X�g������
    am.invokeMethod("initPoplist");
    
    //Table���[�W�����̕\���s���ݒ�֐�    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"QuoteLineAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_017_A01_01"
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
      setErrorMode(pageContext, webBean);
    }

    // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Add Start
    // ����{�^���ȊO�̃{�^����\�����Ȃ��A���͍��ڂ𖳌��ɐݒ�
    if ( XxcsoQuoteConstants.TRANDIV_READ_ONLY.equals(tranDiv) )
    {
      setItemsDisabled(webBean);
    }
    // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Add End

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g����������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    XxcsoUtils.debug(pageContext, "[START]");

    super.processFormRequest(pageContext, webBean);
    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    // URL����p�����[�^���擾���܂��B
    String quoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String returnPgName = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3);
    String tranDiv = 
      pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // �߂���ʂ̐ݒ�
    if ( returnPgName == null || "".equals(returnPgName.trim()) )
    {
     // ���j���[���
     if ( tranDiv == null )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_MENU
       );
     }
     // ���ό������
     // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod Start
     //else if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) )
       else if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) ||
                  XxcsoQuoteConstants.TRANDIV_READ_ONLY.equals(tranDiv))
     // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Mod End
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_SEARCH
       );
     }
    }
    XxcsoUtils.debug(
      pageContext,
      "�߂��F"
      + pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3)
    );

    // URL����p�����[�^���Ď擾���܂��B
    returnPgName = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY3);

    // AM�֓n���������쐬���܂��B
    Serializable[] pgnameparams = {
      returnPgName
    };

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u����v�{�^��
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      if ( XxcsoQuoteConstants.PARAM_SEARCH.equals(returnPgName) )
      {
        // ���ό�����ʂ֑J��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_QUOTE_SEARCH_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
      else
      {
        // ���j���[��ʂ֑J��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_OA_HOME_PAGE,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true,
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO
        );
      }
    }
    // �u�R�s�[�̍쐬�v�{�^��
    if ( pageContext.getParameter("CopyCreateButton") != null )
    {

      //�p�����[�^�l�擾
      HashMap params
        = (HashMap)am.invokeMethod("handleCopyCreateButton", pgnameparams);
      // ����ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�����ɂ���v�{�^��
    if ( pageContext.getParameter("InvalidityButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleInvalidityButton");

      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�K�p�v�{�^��
    if ( pageContext.getParameter("ApplicableButton") != null )
    {
      HashMap returnValue
        = (HashMap)am.invokeMethod("handleApplicableButton", pgnameparams);

      HashMap params
        = (HashMap)returnValue.get(XxcsoQuoteConstants.RETURN_PARAM_URL);
      OAException msg
        = (OAException)returnValue.get(XxcsoQuoteConstants.RETURN_PARAM_MSG);
        
      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�ł̉����v�{�^��
    if ( pageContext.getParameter("RevisionButton") != null )
    {
      HashMap params
        = (HashMap)am.invokeMethod("handleRevisionButton", pgnameparams);

      // ����ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�m��v�{�^��
    if ( pageContext.getParameter("FixedButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleFixedButton");

      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u���Ϗ�����v�{�^��
    if ( pageContext.getParameter("QuoteSheetPrintButton") != null )
    {
      OAException msg
        = (OAException)am.invokeMethod("handlePdfCreateButton");

      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );
      
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �uCSV�쐬�v�{�^��
    if ( pageContext.getParameter("CsvCreateButton") != null )
    {
      OAException msg = (OAException)am.invokeMethod("handleCsvCreateButton");

      // ���b�Z�[�W�ݒ�
      pageContext.putDialogMessage(msg);

      // ����ʑJ��
      HashMap params = new HashMap(3);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoQuoteConstants.TRANDIV_UPDATE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,quoteHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY3
       ,returnPgName
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�����≮�p���͉�ʂցv�{�^��
    if ( pageContext.getParameter("StoreButton") != null )
    {
      //�p�����[�^�l�擾
      HashMap params = (HashMap)am.invokeMethod("handleStoreButton");

      // �����≮�p���ϓ��͉�ʑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    // �u�s�̒ǉ��v�{�^��
    if ( pageContext.getParameter("AddLineButton") != null )
    {
      am.invokeMethod("handleAddLineButton");
    }
    // �u�s�̍폜�v�{�^��
    if ( pageContext.getParameter("DelLineButton") != null )
    {
      am.invokeMethod("handleDelLineButton");
    }
    // �u�ʏ�X�[���i���o�v�{�^��
    if ( pageContext.getParameter("RegularPriceButton") != null )
    {
      am.invokeMethod("handleRegularPriceButton");
    }

    // ���ϋ敪���ύX���ꂽ�ꍇ�A���ԁi�I���j���ύX����
    if ( "QuoteDivChangeEvent".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM)
         )
       )
    {
      // URL����p�����[�^���擾���܂��B
      String quoteLineId = 
        pageContext.getParameter("EventLineId");

      // AM�֓n���������쐬���܂��B
      Serializable[] params = {
        quoteLineId
      };

      am.invokeMethod("handleDivChange" ,params);
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʂ��G���[���[�h�ɐݒ肵�܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setErrorMode(OAPageContext pageContext, OAWebBean webBean)
  {
    webBean.findChildRecursive("CopyCreateButton").setRendered(false);
    webBean.findChildRecursive("InvalidityButton").setRendered(false);
    webBean.findChildRecursive("ApplicableButton").setRendered(false);
    webBean.findChildRecursive("RevisionButton").setRendered(false);
    webBean.findChildRecursive("FixedButton").setRendered(false);
    webBean.findChildRecursive("QuoteSheetPrintButton").setRendered(false);
    webBean.findChildRecursive("CsvCreateButton").setRendered(false);
    webBean.findChildRecursive("InputTranceButton").setRendered(false);
    webBean.findChildRecursive("MainSlRN").setRendered(false);
  }

  // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Add Start
  /*****************************************************************************
   * ����{�^���ȊO�̃{�^����\�����Ȃ��A���͍��ڂ𖳌��ɐݒ�B
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setItemsDisabled(OAWebBean webBean)
  {
    //�R�s�[�̍쐬�{�^��
    if (null != webBean.findChildRecursive("CopyCreateButton"))
    {
      webBean.findChildRecursive("CopyCreateButton").setRendered(false);
    }
    //�����ɂ���{�^��
    if (null != webBean.findChildRecursive("InvalidityButton"))
    {
      webBean.findChildRecursive("InvalidityButton").setRendered(false);
    }
    //�K�p�{�^��
    if (null != webBean.findChildRecursive("ApplicableButton"))
    {
      webBean.findChildRecursive("ApplicableButton").setRendered(false);
    }
    //�ł̉����{�^��
    if (null != webBean.findChildRecursive("RevisionButton"))
    {
      webBean.findChildRecursive("RevisionButton").setRendered(false);
    }
    //�m��{�^��
    if (null != webBean.findChildRecursive("FixedButton"))
    {
      webBean.findChildRecursive("FixedButton").setRendered(false);
    }
    //���Ϗ����
    if (null != webBean.findChildRecursive("QuoteSheetPrintButton"))
    {
      webBean.findChildRecursive("QuoteSheetPrintButton").setRendered(false);
    }
    //CSV�쐬
    if (null != webBean.findChildRecursive("CsvCreateButton"))
    {
      webBean.findChildRecursive("CsvCreateButton").setRendered(false);
    }
    //�����≮�p���͉�ʂփ{�^��
    if (null != webBean.findChildRecursive("StoreButton"))
    {
      webBean.findChildRecursive("StoreButton").setRendered(false);
    }
    //���s��
    if (null != webBean.findChildRecursive("PublishDate"))
    {
      ((TextInputBean)webBean.findChildRecursive(
        "PublishDate")).setDisabled(true);
    }
    //�ڋq�R�[�h
    if (null != webBean.findChildRecursive("AccountNumber"))
    {
      ((OAMessageLovInputBean)webBean.findChildRecursive(
        "AccountNumber")).setDisabled(true);
    }
    //�[���ꏊ
    if (null != webBean.findChildRecursive("DeliveryPlace"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "DeliveryPlace")).setDisabled(true);
    }
    //�x������
    if (null != webBean.findChildRecursive("PaymentCondition"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "PaymentCondition")).setDisabled(true);
    }
    //���Ϗ���o�於
    if (null != webBean.findChildRecursive("QuoteSubmitName"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "QuoteSubmitName")).setDisabled(true);
    }
    //�X�[���i�ŋ敪
    if (null != webBean.findChildRecursive("DelivPriceTaxType"))
    {
      ((OAMessageChoiceBean)webBean.findChildRecursive(
        "DelivPriceTaxType")).setDisabled(true);
    }
    //�������i�ŋ敪
    if (null != webBean.findChildRecursive("StorePriceTaxType"))
    {
      ((OAMessageChoiceBean)webBean.findChildRecursive(
        "StorePriceTaxType")).setDisabled(true);
    }
    //�P���敪
    if (null != webBean.findChildRecursive("UnitType"))
    {
      ((OAMessageChoiceBean)webBean.findChildRecursive(
        "UnitType")).setDisabled(true);
    }
    //���L����
    if (null != webBean.findChildRecursive("SpecialNote"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "SpecialNote")).setDisabled(true);
    }
    //�I��
    if (null != webBean.findChildRecursive("QuoteSelection"))
    {
      ((OAMultipleSelectionBean)webBean.findChildRecursive(
        "QuoteSelection")).setDisabled(true);
    }
    //���i�R�[�h
    if (null != webBean.findChildRecursive("InventoryItemCode"))
    {
      ((OAMessageLovInputBean)webBean.findChildRecursive(
        "InventoryItemCode")).setDisabled(true);
    }
    //���ς�敪
    if (null != webBean.findChildRecursive("QuoteDiv"))
    {
      ((OAMessageChoiceBean)webBean.findChildRecursive(
        "QuoteDiv")).setDisabled(true);
    }
    //�ʏ�X�[���i
    if (null != webBean.findChildRecursive("UsuallyDelivPrice"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "UsuallyDelivPrice")).setDisabled(true);
    }
    //�ʏ�X������
    if (null != webBean.findChildRecursive("UsuallyStoreSalesPrice"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "UsuallyStoreSalesPrice")).setDisabled(true);
    }
    //����X�[���i
    if (null != webBean.findChildRecursive("ThisTimeDelivPrice"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "ThisTimeDelivPrice")).setDisabled(true);
    }
    //����X������
    if (null != webBean.findChildRecursive("ThisTimeStoreSalesPrice"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "ThisTimeStoreSalesPrice")).setDisabled(true);
    }
    //���ԁi�J�n�j
    if (null != webBean.findChildRecursive("QuoteStartDate"))
    {
      ((TextInputBean)webBean.findChildRecursive(
        "QuoteStartDate")).setDisabled(true);
    }
    //���ԁi�I���j
    if (null != webBean.findChildRecursive("QuoteEndDate"))
    {
      ((TextInputBean)webBean.findChildRecursive(
        "QuoteEndDate")).setDisabled(true);
    }
    //���я�
    if (null != webBean.findChildRecursive("LineOrder"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "LineOrder")).setDisabled(true);
    }
    //���l
    if (null != webBean.findChildRecursive("Remarks"))
    {
      ((OAMessageTextInputBean)webBean.findChildRecursive(
        "Remarks")).setDisabled(true);
    }
    //�s�̒ǉ�
    if (null != webBean.findChildRecursive("AddLineButton"))
    {
      webBean.findChildRecursive("AddLineButton").setRendered(false);
    }
    //�s�̍폜
    if (null != webBean.findChildRecursive("DelLineButton"))
    {
      webBean.findChildRecursive("DelLineButton").setRendered(false);
    }
    //�ʏ�X�[���i���o
    if (null != webBean.findChildRecursive("RegularPriceButton"))
    {
      webBean.findChildRecursive("RegularPriceButton").setRendered(false);
    }
  }
  // 2012-09-10 Ver1.1 [E_�{�ғ�_09945] Add End
}
