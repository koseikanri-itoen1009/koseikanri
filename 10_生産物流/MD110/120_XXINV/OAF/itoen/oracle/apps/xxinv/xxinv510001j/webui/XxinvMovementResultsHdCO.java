/*============================================================================
* �t�@�C���� : XxinvMovementResultsHdCO
* �T�v����   : ���o�Ɏ��уw�b�_:�����R���g���[��
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �勴�F�Y     �V�K�쐬
* 2008-07-25 1.1  �R�{���v     �s��w�E�����C��
* 2008-08-18 1.2  �R�{���v     �����ύX#157�Ή��AST#249�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

import oracle.apps.fnd.common.VersionInfo;

import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.common.MessageToken;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import java.util.Hashtable;
import java.io.Serializable;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * ���o�Ɏ��уw�b�_:�����R���g���[���ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementResultsHdCO extends XxcmnOAControllerImpl
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

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
    // �O���URL�擾
    String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
    String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
// 2008/08/18 v1.2 Y.Yamamoto Mod End
    
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N �߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
      // �O���URL�擾
//      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

      // �_�C�A���OYES�{�^��������
      if (pageContext.getParameter("yesBtn") != null)
      {
        // �X�V����(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
        String retCode = (String)am.invokeMethod("UpdateHdr");

        // ����I���̏ꍇ�A�R�~�b�g����
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;
          // ����I��(�X�V�L)�̏ꍇ(MovHdrId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode))
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }
          
          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
          // �R�~�b�g
          am.invokeMethod("doCommit");

          // ����I��(�X�V�L)�̏ꍇ
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag))
          {
            // OA��O���X�g�𐶐����܂��B
            ArrayList exceptions = new ArrayList(100);
            // �R���J�����g�F�ړ����o�Ɏ��ѓo�^�������s
            HashMap retParams = new HashMap();
            retParams = (HashMap)am.invokeMethod("doMovActualMake");

            // �R���J�����g������I�������ꍇ
            if (XxcmnConstants.RETURN_SUCCESS.equals((String)retParams.get("retFlag")))
            {
              // ���b�Z�[�W�g�[�N���擾
              MessageToken[] tokens = new MessageToken[2];
              tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID, retParams.get("requestId").toString());
              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                              XxinvConstants.XXINV10006,
                                              tokens,
                                              OAException.INFORMATION,
                                              null));
  
            }
            // �X�V��������MSG��ݒ肵�A����ʑJ��
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10158, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));
            // ���b�Z�[�W���o�͂��A�����I��
            if (exceptions.size() > 0)
            {
              OAException.raiseBundledOAException(exceptions);
            }
          }

        // ����I���łȂ��ꍇ�A���[���o�b�N
        } else
        {
          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
          am.invokeMethod("doRollBack");
        }

      // �_�C�A���ONO�{�^��������
      } else if (pageContext.getParameter("noBtn") != null)
      {
        // �������Ȃ�(�ĕ\��)
      // �_�C�A���OYES�{�^��������
      } else if (pageContext.getParameter("yesNextBtn") != null)
      {
        // �������Ȃ�(�ĕ\��)
      
      } else if (pageContext.getParameter("noNextBtn") != null)
      {
        // �������Ȃ�(�ĕ\��)

      // ���փ{�^��������
      } else if (pageContext.getParameter("Next") != null)
      {
        // �������Ȃ�(�ĕ\��)
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//      } else if (!XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
      } else if (XxinvConstants.URL_XXINV510001JS.equals(prevUrl))
// 2008/08/18 v1.2 Y.Yamamoto Mod End
      {

        // �O��ʂ̒l�擾
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // �]�ƈ��敪
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // ���уf�[�^�敪
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // ���i���ʋ敪
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
// 2008/08/18 v1.2 Y.Yamamoto Mod End
        String updateFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG); // �X�V�t���O

        // ���i�敪�̎擾
        String itemClass  = pageContext.getProfile("XXCMN_ITEM_DIV_SECURITY");

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        HashMap searchParamsHd = new HashMap();
        searchParamsHd.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        searchParamsHd.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        searchParamsHd.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
        searchParamsHd.put(XxinvConstants.URL_PARAM_ITEM_CLASS, itemClass);
        searchParamsHd.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);

        // �����ݒ�
        Serializable setParamsHd[] = { searchParamsHd };
        // initialize�̈����^�ݒ�
        Class[] parameterTypesHd = { HashMap.class };
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // �p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        searchParams.put(XxinvConstants.URL_PARAM_ITEM_CLASS, itemClass);
//        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, updateFlag);
        searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);
        searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // �����ݒ�
        Serializable setParams[] = { searchParams };
        // initialize�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // VO����������
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
//        am.invokeMethod("initializeHdr", setParams, parameterTypes);
        am.invokeMethod("initializeHdr", setParamsHd, parameterTypesHd);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // �X�V�t���O��NULL�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(updateFlag))
        {
          // �V�K�s�ǉ�����
          am.invokeMethod("addRow");
        } else 
        {
          // �����ݒ�
          Serializable params[] = { searchHdrId };
          // ��������
          am.invokeMethod("doSearchHdr", params);

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
          // ��������
          am.invokeMethod("doSearchLine", setParams, parameterTypes);
// 2008/08/18 v1.2 Y.Yamamoto Mod End
        }
      }

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else 
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510001J, true))
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
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �����t���O�̎擾
      String updateFlag  = pageContext.getParameter("ProcessFlag");

// 2008/08/18 v1.2 Y.Yamamoto Mod Start
      // �O���URL�擾
      String prevUrl = pageContext.getParameter(XxinvConstants.URL_PARAM_PREV_URL);
// 2008/08/18 v1.2 Y.Yamamoto Mod End

      // ********************************* //
      // *      ����{�^��������         * //
      // ********************************* //
      if (pageContext.getParameter("Cancel") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

// 2008/08/20 v1.2 Y.Yamamoto Mod Start
        // �ύX�Ɋւ���x���N���A�������s
        am.invokeMethod("clearWarnAboutChanges");
// 2008/08/20 v1.2 Y.Yamamoto Mod End
        // ���o�Ɏ��їv���ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JS,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // ********************************* //
      // *      ���փ{�^��������         * //
      // ********************************* //
      } else if (pageContext.getParameter("Next") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);
// 2008/08/20 v1.6 Y.Yamamoto Mod Start
        // �ύX�Ɋւ���x������
        am.invokeMethod("doWarnAboutChanges");
// 2008/08/20 v1.6 Y.Yamamoto Mod End

        // ��������(�ړ��w�b�_ID)�擾
        String searchMovHdrId = pageContext.getParameter("HdrId");

        // ���փ`�F�b�N
        am.invokeMethod("checkHdr");

        // �p���b�g�����̃`�F�b�N
        am.invokeMethod("chckPallet");

        // �ғ����`�F�b�N
        String returnCode = (String)am.invokeMethod("oprtnDayCheck");

        // �_�C�A���O�쐬
        if (!XxcmnConstants.STRING_TRUE.equals(returnCode))
        {
          // �_�C�A���O���b�Z�[�W��\��
          MessageToken[] tokens = new MessageToken[1];
          if ("1".equals(returnCode))
          {
            // �G���[���b�Z�[�W�g�[�N���擾
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          } else if ("2".equals(returnCode))
          {
            // �G���[���b�Z�[�W�g�[�N���擾
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          }
          // ���C�����b�Z�[�W�쐬
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXINV
                                                    ,XxinvConstants.XXINV10058
                                                    ,tokens);
          //�p�����[�^�pHashMap����
          Hashtable pageParams = new Hashtable();
          // ��������(�ړ��w�b�_ID)�擾
          pageParams.put("pHdrId", searchMovHdrId);

          // �_�C�A���O����
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510001JL,
            XxinvConstants.URL_XXINV510001JH,
            "YES",
            "NO",
            "yesNextBtn",
            "noNextBtn",
            pageParams);
        }

        // �p�����[�^�擾
        String peopleCode  = pageContext.getParameter("Peoplecode");
        String actualFlag  = pageContext.getParameter("Actual");
        String productFlag = pageContext.getParameter("Product");
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);

        // �w�b�_ID�����͂���Ă����ꍇ
// 2008/08/18 v1.2 Y.Yamamoto Mod Start
        if (!XxcmnUtility.isBlankOrNull(searchMovHdrId))
        {
          //�p�����[�^�pHashMap����
          pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");

// 2008/08/25 v1.2 Y.Yamamoto Mod Start
          HashMap searchParams = new HashMap();
          searchParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
          searchParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
          searchParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
          searchParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
          searchParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2");

          // �����ݒ�
          Serializable setParams[] = { searchParams };
          // initialize�̈����^�ݒ�
          Class[] parameterTypes = { HashMap.class };

          // ��������
          am.invokeMethod("doLotSwitcher", setParams, parameterTypes);
// 2008/08/25 v1.2 Y.Yamamoto Mod End
        } else if (XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
        { // �O�̉�ʂ����׉�ʂ̂Ƃ��͍X�V�t���O���Z�b�g
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");
        }
// 2008/08/18 v1.2 Y.Yamamoto Mod End

        // ���o�Ɏ��і��׉�ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JL,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // �_�C�A���OYES�{�^��������
      } else if (pageContext.getParameter("yesNextBtn") != null)
      {
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();

        // �p�����[�^�擾
        String searchMovHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID); // �w�b�_ID
        String peopleCode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);   // �]�ƈ��敪
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);   // ���уf�[�^�敪
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG); // ���i���ʋ敪
        // �_�C�A���O��ʂ�薾�׉�ʂ֑J�ڂ��邽�߁A�p�����[�^�Đݒ�
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchMovHdrId);
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peopleCode);
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG, actualFlag);
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG, productFlag);
// 2008/08/18 v1.2 Y.Yamamoto Mod Start

        // �w�b�_ID�����͂���Ă����ꍇ
//        if (!XxcmnUtility.isBlankOrNull(searchMovHdrId))
//        {
//          //�p�����[�^�pHashMap����
//          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "2"); // �X�V�t���O
//        }
        if (XxinvConstants.URL_XXINV510001JL.equals(prevUrl))
        { // �O�̉�ʂ����׉�ʂ̂Ƃ��͍X�V�t���O���Z�b�g
          pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, "1");
        }
// 2008/08/18 v1.2 Y.Yamamoto Mod End


        // ���o�Ɏ��і��׉�ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JL,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // �_�C�A���ONO�{�^��������
      } else if (pageContext.getParameter("noNextBtn") != null)
      {
        // �����������Ȃ�

      // ********************************* //
      // *      �K�p�{�^��������         * //
      // ********************************* //
      } else if (pageContext.getParameter("Go") != null)
      {

        // �o�^�E�X�V���̃`�F�b�N
        am.invokeMethod("checkHdr");

        // �p���b�g�����̃`�F�b�N
        am.invokeMethod("chckPallet");

        // �ғ����`�F�b�N
        String returnCode = (String)am.invokeMethod("oprtnDayCheck");

        // �_�C�A���O�쐬
        if (!XxcmnConstants.STRING_TRUE.equals(returnCode))
        {
          // �_�C�A���O���b�Z�[�W��\��
          MessageToken[] tokens = new MessageToken[1];
          if ("1".equals(returnCode))
          {
            // �G���[���b�Z�[�W�g�[�N���擾
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          } else if ("2".equals(returnCode))
          {
            // �G���[���b�Z�[�W�g�[�N���擾
            tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          }
          // ���C�����b�Z�[�W�쐬
          OAException mainMessage = new OAException(XxcmnConstants.APPL_XXINV
                                                    ,XxinvConstants.XXINV10058
                                                    ,tokens);
          //�p�����[�^�pHashMap����
          Hashtable pageParams = new Hashtable();
          // ��������(�ړ��w�b�_ID)�擾
          String searchMovHdrId = pageContext.getParameter("HdrId");
          pageParams.put("pHdrId", searchMovHdrId);

          // �_�C�A���O����
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510001JH,
            XxinvConstants.URL_XXINV510001JH,
            "YES",
            "NO",
            "yesBtn",
            "noBtn",
            pageParams);
        }

        // �X�V����(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
        String retCode = (String)am.invokeMethod("UpdateHdr");

        // ����I���̏ꍇ�A�R�~�b�g����
        if (!XxcmnConstants.STRING_FALSE.equals(retCode))
        {
          String updFlag = XxcmnConstants.STRING_FALSE;

          // ����I��(�X�V�L)�̏ꍇ(MovHdrId)
          if (!XxcmnConstants.STRING_TRUE.equals(retCode))
          {
            updFlag = XxcmnConstants.STRING_TRUE;
          }

          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          // �R�~�b�g
          am.invokeMethod("doCommit");

          // ����I��(�X�V�L)�̏ꍇ
          if (!XxcmnConstants.STRING_FALSE.equals(updFlag))
          {
            // OA��O���X�g�𐶐����܂��B
            ArrayList exceptions = new ArrayList(100);

            // �R���J�����g�F�ړ����o�Ɏ��ѓo�^�������s
            HashMap retParams = new HashMap();
            retParams = (HashMap)am.invokeMethod("doMovActualMake");

            // �R���J�����g������I�������ꍇ
            if (XxcmnConstants.RETURN_SUCCESS.equals((String)retParams.get("retFlag")))
            {
              // ���b�Z�[�W�g�[�N���擾
              MessageToken[] tokens = new MessageToken[2];
              tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
              tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID, retParams.get("requestId").toString());
              exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                              XxinvConstants.XXINV10006,
                                              tokens,
                                              OAException.INFORMATION,
                                              null));
  
            }
            // �X�V��������MSG��ݒ肵�A����ʑJ��
            exceptions.add( new OAException(XxcmnConstants.APPL_XXINV,
                                   XxinvConstants.XXINV10158, 
                                   null, 
                                   OAException.INFORMATION, 
                                   null));
            // ���b�Z�[�W���o�͂��A�����I��
            if (exceptions.size() > 0)
            {
              OAException.raiseBundledOAException(exceptions);
            }
          }

        // ����I���łȂ��ꍇ�A���[���o�b�N
        } else
        {
          //�y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510001J);

          am.invokeMethod("doRollBack");
        }
        
      // ********************************** //
      // *         �V�K�쐬�̏ꍇ         * //
      // ********************************** //
      } else if (XxinvConstants.PROCESS_FLAG_I.equals(updateFlag))
      {
        // �o�ɓ�(����)���ύX���ꂽ�ꍇ
        if ("actualShipDate".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // �R�s�[����
          am.invokeMethod("copyActualShipDate");

        // ����(����)���ύX���ꂽ�ꍇ
        } else if ("actualArrivalDate".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // �R�s�[����
          am.invokeMethod("copyActualArrivalDate");

        // �^���敪���ύX���ꂽ�ꍇ
        } else if ("frtChargeClass".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // �^���敪�擾
          String freightChargeClass = pageContext.getParameter("freightChargeClass");

          // �^���敪��OFF�̏ꍇ
          if (XxinvConstants.FREIGHT_CHARGE_CLASS_1.equals(freightChargeClass))
          {
            // �N���A����
            am.invokeMethod("clearValue");
    // mod start ver1.1
//          } else
//          {
            // �^���Ǝғ��͐��䏈��
//            am.invokeMethod("inputFreightCarrier");
    // mod end ver1.1
          }

        }

      // ********************************** //
      // *           �X�V�̏ꍇ           * //
      // ********************************** //
      } else if (XxinvConstants.PROCESS_FLAG_U.equals(updateFlag))
      {
        // �^���敪���ύX���ꂽ�ꍇ
        if ("frtChargeClass".equals(pageContext.getParameter(EVENT_PARAM)))
        {
          // �N���A����
          am.invokeMethod("clearValue");
        }
      }

    // ��O�����������ꍇ
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
    
  }

}
