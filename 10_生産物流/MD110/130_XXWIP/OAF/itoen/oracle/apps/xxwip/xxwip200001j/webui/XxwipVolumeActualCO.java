/*============================================================================
* �t�@�C���� : XxwipVolumeActualCO
* �T�v����   : �o�������ѓ��̓R���g���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  ��r���     �V�K�쐬
* 2008-05-12      ��r���     �ύX�v���Ή�(#75)
* 2009-01-15 1.1  ��r���     �{�ԏ�Q#836�P�v�Ή��U
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OAPageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
import oracle.apps.fnd.framework.webui.beans.layout.OATableLayoutBean;
import oracle.apps.fnd.framework.webui.beans.table.OAAdvancedTableBean;
/***************************************************************************
 * �o�������ѓ��̓R���g���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.1
 ***************************************************************************
 */
public class XxwipVolumeActualCO extends XxcmnOAControllerImpl
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

    // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
      TransactionUnitHelper.startTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);

      // �N�C�b�N�����p�l���̐���
      OAPageLayoutBean pageLayout = pageContext.getPageLayoutBean();
      // quickSearchRN�̐���
      OATableLayoutBean qsRN = (OATableLayoutBean)createWebBean(pageContext,
                               "/itoen/oracle/apps/xxwip/util/webui/BatchNoQuickSearchRN",
                               "QuickSearchRN",
                               true);
      // quickSearchRN�̐ݒ�
      pageLayout.setQuickSearch(qsRN);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // ����������
      am.invokeMethod("initialize");
      // �����o�b�`ID
      String searchBatchId = null;
      // �����{�^���������ꂽ�ꍇ
      if (pageContext.getParameter(XxwipConstants.QS_SEARCH_BTN) != null) 
      {
        // ���������擾
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID);
        // �����ݒ�
        Serializable params[] = { searchBatchId };
        // ��������
        am.invokeMethod("doSearch", params);
      // �_�C�A���O��ʂ���uYes�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Yes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // �����ݒ�
        Serializable param[] = { searchBatchId };
        am.invokeMethod("doCommit", param);
        // �����ݒ�
        Serializable params[] = { searchBatchId };
        // ��������
        am.invokeMethod("doSearch", params);
      // �_�C�A���O��ʂ���uNo�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("No") != null) 
      {
        am.invokeMethod("doRollBack");
      // �����_�C�A���O��ʂ���uYes�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("ReserveYes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // �K�p�������s���܂��B
        apply(pageContext, webBean, am, searchBatchId);
      // �����_�C�A���O��ʂ���uNo�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("ReserveNo") != null) 
      {
        // �������Ȃ�
// 2009-01-15 v1.1 D.Nihei Add Start �{�ԏ�Q#836�P�v�Ή��U
      // �p�~�_�C�A���O��ʂ���uYes�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("CloseYes") != null) 
      {
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        // �����ݒ�
        Serializable params[] = { searchBatchId };
        // �p�~�������s���܂��B
        am.invokeMethod("doClose");
        // ���C�����b�Z�[�W�쐬 
        MessageToken[] mainTokens = new MessageToken[1];
        mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, "�Y���̎�z�́A�p�~����܂����B");

        throw new OAException(XxcmnConstants.APPL_XXCMN,
                                                  XxcmnConstants.XXCMN00025,
                                                  mainTokens,
                                                  OAException.INFORMATION,
                                                  null);
      // �p�~�_�C�A���O��ʂ���uNo�v���������ꂽ�ꍇ
      } else if (pageContext.getParameter("CloseNo") != null) 
      {
        // �������Ȃ�
// 2009-01-15 v1.1 D.Nihei Add End
      } else if (pageContext.getParameter("LotDetailInvest") == null &&
                 pageContext.getParameter("LotDetailReInvest") == null)
      {
        // ���������擾
        searchBatchId = pageContext.getParameter(XxwipConstants.URL_PARAM_MOVE_BATCH_ID);
        if (!XxcmnUtility.isBlankOrNull(searchBatchId))
        {
          // �����ݒ�
          Serializable params[] = { searchBatchId };
          // ��������
          am.invokeMethod("doSearch", params);
        }
      }
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwipConstants.TXN_XXWIP200002J, true))
      { 
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
    try
    {
      super.processFormRequest(pageContext, webBean);
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �����{�^���������ꂽ�ꍇ
      if (pageContext.getParameter(XxwipConstants.QS_SEARCH_BTN) != null) 
      {
        // ���������擾
        String searchBatchId = pageContext.getParameter(XxwipConstants.PARAM_SC_BATCH_ID);
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID, searchBatchId);
        // ����ʑJ��
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

// 2009-01-15 v1.1 D.Nihei Add Start �{�ԏ�Q#836�P�v�Ή��U
      // �p�~�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Close") != null) 
      {
        // ���������擾
        String batchId = pageContext.getParameter(XxwipConstants.PARAM_SC_BATCH_ID);
        //�p�����[�^�pHashMap����
        Hashtable pageParams = new Hashtable();
        pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
        // ���C�����b�Z�[�W�쐬 
        MessageToken[] mainTokens = new MessageToken[1];
        mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, "�Y���̎�z��p�~���܂��B��낵���ł����H");

        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                  XxcmnConstants.XXCMN00025,
                                                  mainTokens);
                                            
        // �_�C�A���O���b�Z�[�W��\��
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxwipConstants.URL_XXWIP200001J,
          XxwipConstants.URL_XXWIP200001J,
          "Yes",
          "No",
          "CloseYes",
          "CloseNo",
          pageParams);          
// 2009-01-15 v1.1 D.Nihei Add End
      // �K�p�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter(XxwipConstants.GO_BTN) != null) 
      {
        // �������ʃ`�F�b�N
        String mainMsg = (String)am.invokeMethod("checkLotQty");
        // �o�b�`ID���擾
        String batchId = pageContext.getParameter("BatchId");
        if (!XxcmnUtility.isBlankOrNull(mainMsg)) 
        {
          //�p�����[�^�pHashMap����
          Hashtable pageParams = new Hashtable();
          pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
          // ���C�����b�Z�[�W�쐬 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, mainMsg);

          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXCMN,
                                                    XxcmnConstants.XXCMN00025,
                                                    mainTokens);
                                            
          // �_�C�A���O���b�Z�[�W��\��
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxwipConstants.URL_XXWIP200001J,
            XxwipConstants.URL_XXWIP200001J,
            "Yes",
            "No",
            "ReserveYes",
            "ReserveNo",
            pageParams);          
        } else
        {
          // �K�p����
          apply(pageContext, webBean, am, batchId);
        }
      // �s�}���{�^���������ꂽ�ꍇ
      } else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // SOURCE_PARAM���擾
        String sourceParam = pageContext.getParameter(SOURCE_PARAM);
        // �^�u�̃^�C�v�p�̕ϐ�
        String tabType = "";
        // �s�}���{�^�����ڐ���(����)
        OAAdvancedTableBean investTtableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("InvestRN");
        // �s�}���{�^�����ڐ���(�ō�)
        OAAdvancedTableBean reInvestTableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("ReInvestRN");
        // �s�}���{�^�����ڐ���(���Y��)
        OAAdvancedTableBean coProdTableBean = 
          (OAAdvancedTableBean)webBean.findChildRecursive("CoProdRN");
        if (sourceParam != null && sourceParam.equals(investTtableBean.getName()))
        {
          // ����
          tabType = XxwipConstants.TAB_TYPE_INVEST;
        }
        if (sourceParam != null && sourceParam.equals(reInvestTableBean.getName()))
        {
          // �ō�
          tabType = XxwipConstants.TAB_TYPE_REINVEST;
        }
        if (sourceParam != null && sourceParam.equals(coProdTableBean.getName()))
        {
          // ���Y��
          tabType = XxwipConstants.TAB_TYPE_CO_PROD;
        }
        // �����ݒ�
        Serializable[] params = { tabType };
        // �s�}������
        am.invokeMethod("addRow", params);

      // ����{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter(XxwipConstants.CANCEL_BTN) != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // �z�[���֑J��
        pageContext.setForwardURL(XxcmnConstants.URL_OAHOMEPAGE,
                                  GUESS_MENU_CONTEXT,
                                  null,
                                  null,
                                  false, // Do not retain AM
                                  ADD_BREAD_CRUMB_NO,
                                  OAWebBeanConstants.IGNORE_MESSAGES);
      // ���Y�����ύX���ꂽ�ꍇ
      } else if ("productDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �R�s�[����
        am.invokeMethod("copyProductDate");
      // ���������ύX���ꂽ�ꍇ
      } else if ("makerDate".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �R�s�[����
        am.invokeMethod("copyMakerDate");
      // �폜�A�C�R�����������ꂽ�ꍇ
      } else if (XxwipConstants.DELETE_ICON.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        String tabType  = (String)pageContext.getParameter(XxwipConstants.PARAM_TAB_TYPE);
        String mtlDtlId = (String)pageContext.getParameter(XxwipConstants.PARAM_MTL_DTL_ID);
        String batchId  = (String)pageContext.getParameter(XxwipConstants.PARAM_BATCH_ID);
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // �����ݒ�
        Serializable[] params = { tabType, batchId, mtlDtlId };
        am.invokeMethod("deleteMaterialLine", params);

      // �������F���b�g���׃{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("LotDetailInvest") != null) 
      {
        // �����ݒ�
        Serializable[] params = { XxwipConstants.TAB_TYPE_INVEST };
        //�p�����[�^�pHashMap����
        HashMap pageParams = (HashMap)am.invokeMethod("doDetail", params);
        // ����ʂփt�H���[�h
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200002J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    
     
      // �ō����F���b�g���׃{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("LotDetailReInvest") != null) 
      {
        // �����ݒ�
        Serializable[] params = { XxwipConstants.TAB_TYPE_REINVEST };
        //�p�����[�^�pHashMap����
        HashMap pageParams = (HashMap)am.invokeMethod("doDetail", params);
        // ����ʂփt�H���[�h
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200002J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
  /***************************************************************************
   * �K�p�������s�����\�b�h�ł��B
   * @param pageContext - �R���e�L�X�g
   * @param webBean     - �E�F�u�r�[��
   * @param pageContext - �A�v���P�[�V�������W���[��
   * @param batchId     - �o�b�`ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void apply(
    OAPageContext pageContext, 
    OAWebBean webBean, 
    OAApplicationModule am, 
    String batchId
    ) throws OAException
  {
    // �^�u���擾
    OASubTabLayoutBean subTabLayout =
      (OASubTabLayoutBean)webBean.findChildRecursive("MaterialSubTab");
    int tabType = subTabLayout.getSelectedIndex(pageContext);
    // �����ݒ�
    Serializable params[] = { batchId, String.valueOf(tabType) };
    // �o�^����
    String exeType = (String)am.invokeMethod("apply", params);
    // ����I���̏ꍇ
    if (XxcmnConstants.RETURN_SUCCESS.equals(exeType)) 
    {
      // �y���ʏ����z�g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      // �����ݒ�
      Serializable param[] = { batchId };
      am.invokeMethod("doCommit", param);
    // �x���I���̏ꍇ
    } else if (XxcmnConstants.RETURN_WARN.equals(exeType))
    {
      // �_�C�A���O���b�Z�[�W��\��
      // ���C�����b�Z�[�W�쐬
      // �g�[�N���𐶐����܂��B
      OAException mainMessage = new OAException(XxcmnConstants.APPL_XXWIP
                                               ,XxwipConstants.XXWIP00007);
      //�p�����[�^�pHashMap����
      Hashtable pageParams = new Hashtable();
      pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId.toString());
      // �_�C�A���O����
      XxcmnUtility.createDialog(
        OAException.CONFIRMATION,
        pageContext,
        mainMessage,
        null,
        XxwipConstants.URL_XXWIP200001J,
        XxwipConstants.URL_XXWIP200001J,
        "Yes",
        "No",
        "Yes",
        "No",
        pageParams);
          
    } else 
    {
      // �y���ʏ����z�g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      am.invokeMethod("doRollBack");
    }
  } // apply
}