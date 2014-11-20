/*============================================================================
* �t�@�C���� : XxpoPoConfirmCO
* �T�v����   : �����m�F���:�����R���g���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-03 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2008-05-07      �ɓ��ЂƂ�   �����ύX�v���Ή�(#41,48)
* 2009-02-24 1.1  ��r�@���   �{�ԏ�Q#6�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * �����m�F���:�����R���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.1
 ***************************************************************************
 */
public class XxpoPoConfirmCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ****************** //
      // *  �G���[������  * //
      // ****************** //
      if (pageContext.getParameter("OrderApproving") != null) 
      {
        // ���������{�^���������͏����͍s�킸�ɁA�ĕ\���B
      
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // �d�������{�^���������͏����͍s�킸�ɁA�ĕ\���B

      // ******************************* // 
      // * ���������_�C�A���OYes������ * //
      // ******************************* // 
      } else if (pageContext.getParameter("OrderApprovingYes") != null) 
      {
        // �X�V�O�`�F�b�N
        am.invokeMethod("doUpdateCheck"); 

        // �������F����
        am.invokeMethod("doOrderApproving");       

        // �������������s
        am.invokeMethod("initialize");

        // �������ړ��͕K�{�`�F�b�N
        am.invokeMethod("doRequiredCheck"); 

        // ����
        am.invokeMethod("doSearch");  

        // �X�V�������b�Z�[�W
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ******************************* // 
      // * �d�������_�C�A���OYes������ * //
      // ******************************* // 
      } else if (pageContext.getParameter("PurchaseApprovingYes") != null) 
      {
        // �X�V�O�`�F�b�N
        am.invokeMethod("doUpdateCheck"); 

        // �d�����F����
        am.invokeMethod("doPurchaseApproving"); 

        // �������������s
        am.invokeMethod("initialize");

        // �������ړ��͕K�{�`�F�b�N
        am.invokeMethod("doRequiredCheck"); 

        // ����
        am.invokeMethod("doSearch");  

        // �X�V�������b�Z�[�W
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ******************************* // 
      // * ���������_�C�A���ONo������ * //
      // ******************************* //
      } else if (pageContext.getParameter("OrderApprovingNo") != null) 
      {
        // ���������{�^���������͏����͍s�킸�ɁA�ĕ\���B

      // ******************************* // 
      // * �d�������_�C�A���ONo������ * //
      // ******************************* //
      } else if (pageContext.getParameter("PurchaseApprovingNo") != null) 
      {
        // ���������{�^���������͏����͍s�킸�ɁA�ĕ\���B

// 2008-02-24 D.Nihei Add Start �{�ԏ�Q#6�Ή�
      // *********************************** //
      // *   �[����FROM���ύX���ꂽ�ꍇ    * //
      // *********************************** //
      } else if ("deliveryDateFrom".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �[����FROM���ύX���ꂽ�ꍇ�͏����͍s�킸�ɁA�ĕ\���B

// 2008-02-24 D.Nihei Add End
      // ****************** //
      // *  ��������      * //
      // ****************** //
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
      
        // �������������s
        am.invokeMethod("initialize");
      }
      
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO350001J, true))
      { 
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      // ************************* //
      // *   �i�ރ{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // �������ړ��͕K�{�`�F�b�N
        am.invokeMethod("doRequiredCheck"); 

        // ����
        am.invokeMethod("doSearch");  

      // ************************* //
      // *   �폜�{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

      // ************************** //
      // *  ���������{�^��������  * //
      // ************************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // �I���`�F�b�N
        am.invokeMethod("doSelectCheck"); 

        // ���C�����b�Z�[�W�쐬
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO, XxpoConstants.XXPO40036);

        // �_�C�A���O���b�Z�[�W��\��
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO350001JS,
          XxpoConstants.URL_XXPO350001JS,
          "Yes",
          "No",
          "OrderApprovingYes",
          "OrderApprovingNo",
          null);

      // ************************** //
      // *  �d�������{�^��������  * //
      // ************************** //
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // �I���`�F�b�N
        am.invokeMethod("doSelectCheck"); 

        // ���C�����b�Z�[�W�쐬
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO, XxpoConstants.XXPO40035);
        
        // �_�C�A���O���b�Z�[�W��\��
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO350001JS,
          XxpoConstants.URL_XXPO350001JS,
          "Yes",
          "No",
          "PurchaseApprovingYes",
          "PurchaseApprovingNo",
          null);

      // ************************* //
      // *   �����N�N���b�N��    * //
      // ************************* //
      } else if ("HeaderNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // ��������(�w�b�_�[ID)�擾
        String searchHeaderId = pageContext.getParameter("searchHeaderId");
        
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID,  searchHeaderId);
        pageParams.put(XxpoConstants.URL_PARAM_UPDATE_FLAG, "1");

        // �����E����Ɖ��ʉ�ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JI,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

// 2008-02-24 D.Nihei Add Start �{�ԏ�Q#6�Ή�
      // *********************************** //
      // *   �[����FROM���ύX���ꂽ�ꍇ    * //
      // *********************************** //
      } else if ("deliveryDateFrom".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �R�s�[����
        am.invokeMethod("copyDeliveryDate");
// 2008-02-24 D.Nihei Add End
      // ******************* //
      // *  �y�[�W���O��   * //
      // ******************* //
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �I���`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
        am.invokeMethod("checkBoxOff");
      }

    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
