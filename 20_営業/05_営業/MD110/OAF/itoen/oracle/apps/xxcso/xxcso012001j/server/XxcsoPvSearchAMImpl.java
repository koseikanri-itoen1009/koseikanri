/*============================================================================
* ファイル名 : XxcsoPvSearchAMImpl
* 概要説明   : パーソナライズビュー表示画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * パーソナライズビュー表示画面のアプリケーション・モジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvSearchAMImpl()
  {
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;


  /*****************************************************************************
   * 初期化処理
   * @param viewId ビューID
   *****************************************************************************
   */
  public void initDetails(String viewId)
  {
    // PopList初期化
    this.initPopList();

    // 汎用検索テーブルインスタンス
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    pvDefFullVo.initQuery("", false);

    // 汎用検索テーブル行インスタンス
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // 取得分繰り返す
    while ( pvDefFullVoRow != null )
    {
      Number lineViewId = pvDefFullVoRow.getViewId();

      // 初期選択のラジオボタン
      if ( viewId != null && viewId.equals(lineViewId.toString()) )
      {
        pvDefFullVoRow.setLineSelectFlag("Y");
      }

      // デフォルトフラグ
      if (XxcsoPvCommonConstants.DEFAULT_FLAG_YES
            .equals( pvDefFullVoRow.getDefaultFlag() )
      )
      {
        // ON(=Y)の場合
        pvDefFullVoRow.setDefaultFlagSwitcher(
          XxcsoPvCommonConstants.DEFAULT_FLAG
        );
      }
      else
      {
        pvDefFullVoRow.setDefaultFlagSwitcher(null);
      }

      // シードデータの判定を行い、更新・削除アイコンの設定を行う
      // シードデータの場合
      if (lineViewId.intValue() == XxcsoPvCommonConstants.VIEW_ID_SEED)
      {
        // ビューの表示-使用不可
        pvDefFullVoRow.setSeedDataFlag(Boolean.TRUE);

        // 更新アイコン-使用不可
        pvDefFullVoRow.setUpdateEnableSwitcher(
          XxcsoPvCommonConstants.UPDATE_DISABLED
        );

        // 削除アイコン-使用不可
        pvDefFullVoRow.setDeleteEnableSwitcher(
          XxcsoPvCommonConstants.DELETE_DISABLED
        );
        
      }
      // シードデータ以外のビューの場合
      else
      {
        // ビューの表示-使用可能
        pvDefFullVoRow.setSeedDataFlag(Boolean.FALSE);

        // 更新アイコン-使用可能
        pvDefFullVoRow.setUpdateEnableSwitcher(
          XxcsoPvCommonConstants.UPDATE_ENABLED
        );

        // 削除アイコン-使用可能
        pvDefFullVoRow.setDeleteEnableSwitcher(
          XxcsoPvCommonConstants.DELETE_ENABLED
        );
        
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

  }
  /*****************************************************************************
   * 取消ボタン押下時処理
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 適用ボタン押下時処理
   *****************************************************************************
   */
  public void handleApplicationButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.commit();

    // 成功メッセージを設定する
    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,XxcsoConstants.TOKEN_VALUE_PV
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoConstants.TOKEN_VALUE_UPDATE
        );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 複製ボタン押下時処理
   * 
   *****************************************************************************
   */
  public HashMap handleCopyButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // 返却用のhashmap
    HashMap retMap = new HashMap();

    this.rollback();

    // パーソナライズビュー作成上限チェック
    mMessage = this.chkPvCreate();
    if (mMessage != null)
    {
      return retMap;
    }

    // 汎用検索テーブルインスタンス
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      mMessage
        = XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
      return retMap;
    }
    // 汎用検索テーブル行インスタンス
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      mMessage
        = XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");

      return retMap;
    }

    boolean isSelect = false;
    String selViewId = "";
    // 取得分繰り返す
    while ( pvDefFullVoRow != null )
    {
      if ("Y".equals(pvDefFullVoRow.getLineSelectFlag()))
      {
        selViewId = pvDefFullVoRow.getViewId().toString();
        isSelect = true;
        break;
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

    // ラジオボタンが選択されていたかチェック
    if ( !isSelect )
    {
      // レコード未選択エラー
      mMessage=
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00133
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoPvCommonConstants.MSG_RECORD
        );
      return retMap;
    }

    // ビューIDがシードデータの場合
    if ( Integer.parseInt(selViewId) == XxcsoPvCommonConstants.VIEW_ID_SEED)
    {
      // viewId=空文字
      retMap.put(
        XxcsoPvCommonConstants.KEY_VIEW_ID
       , ""
      );
      // 実行区分=新規作成
      retMap.put(
        XxcsoPvCommonConstants.KEY_EXEC_MODE
       ,XxcsoPvCommonConstants.EXECUTE_MODE_CREATE
      );
    }
    else
    {
      // viewId=選択されたビューID
      retMap.put(
        XxcsoPvCommonConstants.KEY_VIEW_ID
       ,selViewId
      );
      // 実行区分=複製
      retMap.put(
        XxcsoPvCommonConstants.KEY_EXEC_MODE
       ,XxcsoPvCommonConstants.EXECUTE_MODE_COPY
      );
    }

    XxcsoUtils.debug(txt, "[END]");

    return retMap;

  }

  /*****************************************************************************
   * ビューの作成ボタン押下時処理
   *****************************************************************************
   */
  public void handleCreateViewButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    // パーソナライズビュー作成上限チェック
    OAException msg = this.chkPvCreate();
    if (msg != null)
    {
      throw msg;
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 更新アイコン押下時処理
   *****************************************************************************
   */
  public void handleUpdateIconClick()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 削除確認画面OKボタン押下時処理
   * @param selViewId     選択された行のviewId
   * @param pvDisplayMode 汎用検索使用モード
   *****************************************************************************
   */
  public void handleDeleteYesButton(
    String selViewId
   ,String pvDisplayMode
    )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    this.rollback();

    String delViewName = "";
    // 汎用検索テーブルインスタンス
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // 汎用検索テーブル行インスタンス
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    // 取得分繰り返す
    while ( pvDefFullVoRow != null )
    {
      // 対象のviewIdのrowを削除
      if ( selViewId.equals(pvDefFullVoRow.getViewId().toString()) ) 
      {
        // 削除前にview名を退避
        delViewName = pvDefFullVoRow.getViewName();

        // 汎用検索テーブル明細テーブル削除処理
        this.removeLine(pvDisplayMode);

        pvDefFullVo.removeCurrentRow();

        this.commit();

        break;
      }
      pvDefFullVoRow = (XxcsoPvDefFullVORowImpl) pvDefFullVo.next();
    }

    // 削除成功メッセージを設定
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoPvCommonConstants.MSG_VIEW_NAME);
    sbMsg.append(XxcsoConstants.TOKEN_VALUE_SEP_LEFT);
    sbMsg.append(delViewName);
    sbMsg.append(XxcsoConstants.TOKEN_VALUE_SEP_RIGHT);   

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoConstants.TOKEN_VALUE_DELETE
        );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * コミット処理
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * Poplist初期化処理
   *****************************************************************************
   */
  private void initPopList()
  {
    // ビューの表示
    XxcsoLookupListVOImpl viewDispLookupVo = getViewDispLookupVO();
    if ( viewDispLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoViewSizeLookupListVO");
    }
    viewDispLookupVo.initQuery("XXCSO1_IB_PV_VIEW_YES_NO", null, "1");
    viewDispLookupVo.executeQuery();
  }

  /*****************************************************************************
   * パーソナライズビュー作成チェック処理
   * @retrun エラーメッセージ
   *****************************************************************************
   */
  private OAException chkPvCreate()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    OAException oaeMsg = null;

    // プロファイルオプション取得
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      return
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // 汎用検索テーブルインスタンス
    XxcsoPvDefFullVOImpl pvDefFullVo = getPvDefFullVO();
    if ( pvDefFullVo == null )
    {
      return XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    // 汎用検索テーブル行インスタンス
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      return XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // 現在のパーソナライズビューがプロファイルサイズ以下かチェックする
    if ( pvDefFullVo.getRowCount() >= Integer.parseInt(maxFetchSize) )
    {
      // ビュー作成上限エラー
      return
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
         ,XxcsoConstants.TOKEN_OBJECT
         ,XxcsoConstants.TOKEN_VALUE_PV
         ,XxcsoConstants.TOKEN_MAX_SIZE
         ,maxFetchSize
        );
    }

    XxcsoUtils.debug(txt, "[END]");

    return oaeMsg;

  }



  /*****************************************************************************
   * 汎用検索テーブルに紐つくテーブルの削除処理
   * （汎用検索表示列定義、汎用検索ソート定義、汎用検索抽出条件定義の削除）
   * @param pvDisplayMode 汎用検索使用Mode
   *****************************************************************************
   */
  private void removeLine(String pvDisplayMode)
  {

    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 汎用検索表示列定義
    XxcsoPvViewColumnFullVOImpl viewColumnVo = getPvViewColumnFullVO();
    if ( viewColumnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    XxcsoPvViewColumnFullVORowImpl viewColumnVoRow
      = (XxcsoPvViewColumnFullVORowImpl) viewColumnVo.first();

    while (viewColumnVoRow != null)
    {
      viewColumnVo.removeCurrentRow();
      viewColumnVoRow = (XxcsoPvViewColumnFullVORowImpl) viewColumnVo.next();
    }

    // 汎用検索ソート定義
    XxcsoPvSortColumnFullVOImpl sortColumnVo = getPvSortColumnFullVO();;
    if ( sortColumnVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    sortColumnVo.initQuery(pvDisplayMode);

    XxcsoPvSortColumnFullVORowImpl sortColumnVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.first();

    while (sortColumnVoRow != null)
    {
      sortColumnVo.removeCurrentRow();
      sortColumnVoRow = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.next();
    }

    //汎用検索抽出条件定義
    XxcsoPvExtractTermFullVOImpl extTermVo = getPvExtractTermFullVO();
    if ( extTermVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    extTermVo.initQuery(pvDisplayMode);

    XxcsoPvExtractTermFullVORowImpl extTermVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermVo.first();

    while (extTermVoRow != null)
    {
      extTermVo.removeCurrentRow();
      extTermVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "XxcsoPvSearchAMLocal");
  }


  /**
   * 
   * Container's getter for ViewDispLookupVO
   */
  public XxcsoLookupListVOImpl getViewDispLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("ViewDispLookupVO");
  }











  /**
   * 
   * Container's getter for PvDefFullVO
   */
  public XxcsoPvDefFullVOImpl getPvDefFullVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("PvDefFullVO");
  }

  /**
   * 
   * Container's getter for PvViewColumnFullVO
   */
  public XxcsoPvViewColumnFullVOImpl getPvViewColumnFullVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("PvViewColumnFullVO");
  }

  /**
   * 
   * Container's getter for PvSortColumnFullVO
   */
  public XxcsoPvSortColumnFullVOImpl getPvSortColumnFullVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("PvSortColumnFullVO");
  }

  /**
   * 
   * Container's getter for PvExtractTermFullVO
   */
  public XxcsoPvExtractTermFullVOImpl getPvExtractTermFullVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("PvExtractTermFullVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefViewColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefViewColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefViewColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefSortColumnVL1
   */
  public ViewLinkImpl getXxcsoPvDefSortColumnVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefSortColumnVL1");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefExtractTermVL1
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL1");
  }

}