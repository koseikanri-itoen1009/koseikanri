/*============================================================================
* �t�@�C���� : XxpoPoInquiryCO
* �T�v����   : �����E����Ɖ���:�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo350001j.webui;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/***************************************************************************
 * �����E����Ɖ��ʃR���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxpoPoInquiryCO extends XxcmnOAControllerImpl
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

      // **************************** //
      // * �T�u�^�u�����N�N���b�N�� *
      // **************************** //
      if ("Line01Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line02Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line03Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line04Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line05Link".equals(pageContext.getParameter(EVENT_PARAM)) || 
          "Line06Link".equals(pageContext.getParameter(EVENT_PARAM))
          )
      {
        // �������s��Ȃ��B

      // ****************** //
      // *  �G���[������  * //
      // ****************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // ���������{�^���������͏����͍s�킸�ɁA�ĕ\���B
      
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // �d�������{�^���������͏����͍s�킸�ɁA�ĕ\���B

      // ****************** //
      // *  �����\������  * //
      // ****************** //
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
      
        // �������������s
        am.invokeMethod("initialize2");

        // ��������
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // �����w�b�_ID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
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
    try
    {
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      
      // ************************* //
      // *   ����{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Reset") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO350001J);
        
        // �����m�F��ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO350001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);
      
      // ************************** //
      // *  ���������{�^��������  * //
      // ************************** //
      } else if (pageContext.getParameter("OrderApproving") != null) 
      {
        // �X�V�O�`�F�b�N
        am.invokeMethod("doUpdateCheck2"); 

        // �������F����
        am.invokeMethod("doOrderApproving2");       

        // �������������s
        am.invokeMethod("initialize2");

        // ��������
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // �����w�b�_ID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
        
        // �X�V�������b�Z�[�W
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);

      // ************************** //
      // *  �d�������{�^��������  * //
      // ************************** //
      } else if (pageContext.getParameter("PurchaseApproving") != null) 
      {
        // �X�V�O�`�F�b�N
        am.invokeMethod("doUpdateCheck2"); 

        // �d�����F����
        am.invokeMethod("doPurchaseApproving2"); 

        // �������������s
        am.invokeMethod("initialize2");

        // ��������
        String searchHeaderId = pageContext.getParameter(XxpoConstants.URL_PARAM_SEARCH_HEADER_ID); // �����w�b�_ID
        Serializable params[] = { searchHeaderId };
        am.invokeMethod("doSearch", params);
        
        // �X�V�������b�Z�[�W
        throw new OAException(
          XxcmnConstants.APPL_XXPO,
          XxpoConstants.XXPO30042, 
          null, 
          OAException.INFORMATION, 
          null);
      }

    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
