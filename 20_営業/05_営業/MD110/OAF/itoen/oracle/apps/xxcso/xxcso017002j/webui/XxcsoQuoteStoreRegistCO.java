/*============================================================================
* �t�@�C���� : XxcsoQuoteStoreRegistCO
* �T�v����   : �����≮�p���ϓ��͉�ʃR���g���[���N���X
* �o�[�W���� : 1.3
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�y���    �V�K�쐬
* 2009-07-23 1.1  SCS������� �y0000806�z�}�[�W���z�^�}�[�W�����̌v�Z�ΏەύX
* 2009-09-10 1.2  SCS�������  �y0001331�z�}�[�W���z�̌v�Z���Ƀy�[�W�J�ڂ��w��
* 2011-04-18 1.3  SCS�g������  �yE_�{�ғ�_01373�z�ʏ�NET���i�������o�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import java.io.Serializable;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.webui.OADialogPage;
import itoen.oracle.apps.xxcso.xxcso017002j.util.XxcsoQuoteConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
/*******************************************************************************
 * �����≮�p���ϓ��͉�ʂ̃R���g���[���N���X
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistCO extends OAControllerImpl
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
    String referenceQuoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);
    String tranDiv = 
      pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);

    // AM�֓n���������쐬���܂��B
    Serializable[] params = {
      quoteHeaderId
     ,referenceQuoteHeaderId
     ,tranDiv
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
    // ***���s�敪�F���ό�����ʁ^�̔��p���ω�ʁ^���j���[����J��
    else
    {
      am.invokeMethod("initDetails", params);      
    }

    // �̔��p���Ϗ��ݒ�
    am.invokeMethod("setAttributeProperty");

    // �ŋ敪�ݒ�
    am.invokeMethod("setAttributeTaxType", params);

    // �|�b�v���X�g������
    am.invokeMethod("initPoplist");

/* 20090723_abe_0000806 START*/
    // �≮���׍s�\�������v���p�e�B�ݒ�
    am.invokeMethod("setLineProperty");
/* 20090723_abe_0000806 END*/

    //Table���[�W�����̕\���s���ݒ�֐�    
    OAException oaeMsg
      = XxcsoUtils.setAdvancedTableRows(
          pageContext
         ,webBean
         ,"QuoteLineAdvTblRN"
         ,"XXCSO1_VIEW_SIZE_017_A02_01"
        );

    if ( oaeMsg != null )
    {
      pageContext.putDialogMessage(oaeMsg);
      setErrorMode(pageContext, webBean);
    }

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
    super.processFormRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");
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
    String referenceQuoteHeaderId = 
      pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);
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
     else if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_SEARCH
       );
     }
     // �̔��p���ω��
     else if ( XxcsoQuoteConstants.TRANDIV_CREATE.equals(tranDiv) )
     {
       pageContext.putParameter(
         XxcsoConstants.TRANSACTION_KEY3,
         XxcsoQuoteConstants.PARAM_SALES
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
      referenceQuoteHeaderId
     ,returnPgName
    };

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u����v�{�^��
    if ( pageContext.getParameter("CancelButton") != null )
    {
      //�p�����[�^�l�擾
      HashMap params
        = (HashMap)am.invokeMethod("handleCancelButton", pgnameparams);

      if ( XxcsoQuoteConstants.PARAM_MENU.equals(returnPgName) )
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

      if ( XxcsoQuoteConstants.PARAM_SALES.equals(returnPgName) )
      {

        // �̔��p���ω�ʂ֑J��
        pageContext.forwardImmediately(
          XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          params,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
      OAException msg
        = (OAException)am.invokeMethod("handleFixedButton");

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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
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
        XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        params,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �m�d�s���i���ύX���ꂽ�ꍇ�A�}�[�W���̎Z�o���s��
    if ( "NetPriceChangeEvent".equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
       )
    {
      // URL����p�����[�^���擾���܂��B
      String quoteLineId = 
        pageContext.getParameter("EventLineId");

      // AM�֓n���������쐬���܂��B
      Serializable[] params = {
        quoteLineId
      };

      am.invokeMethod("handleMarginCalculation" ,params);
    }
    /* 20090910_abe_0001331 START*/
    else
    {
      // ���l�̎Z�o���s��
      am.invokeMethod("handleValidateReference");

      // �̔��p���Ϗ��ݒ�
      am.invokeMethod("setAttributeProperty");
      /* 20090723_abe_0000806 START*/
      // �≮���׍s�\�������v���p�e�B�ݒ�
      am.invokeMethod("setLineProperty");
      /* 20090723_abe_0000806 END*/

    }

// 2010-04-18 v1.3 T.Yoshimoto Add Start E_�{�ғ�_01373
    // �u�ʏ�NET���i�擾�v�{�^��������
    if ( pageContext.getParameter("UsuallNetPriceButton" ) != null )
    {
      // �ʏ�NET���i�̎擾���s��
      am.invokeMethod("handleUsuallNetPriceButton");

    }
// 2010-04-18 v1.3 T.Yoshimoto Add End E_�{�ғ�_01373

    /* 20090910_abe_0001331 END*/
      String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
      XxcsoUtils.debug(pageContext, "event = " + event);
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
    webBean.findChildRecursive("MainSlRN").setRendered(false);
  }
}
