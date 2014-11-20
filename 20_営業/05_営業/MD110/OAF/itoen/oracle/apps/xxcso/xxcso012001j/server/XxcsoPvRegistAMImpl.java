/*============================================================================
* ファイル名 : XxcsoPvRegistAMImpl
* 概要説明   : パーソナライズビュー作成画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-07 1.0  SCS柳平直人  新規作成
* 2009-04-24 1.1  SCS柳平直人  [ST障害T1_634]作業依頼中フラグ追加対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

import java.util.ArrayList;

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewLinkImpl;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoConsciousLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso012001j.poplist.server.XxcsoVendorTypeListVOImpl;

/*******************************************************************************
 * パーソナライズビュー作成画面のアプリケーション・モジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * 初期化処理(新規作成)
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索使用モード
   *****************************************************************************
   */
  public void initCreateDetails(
    String viewId
   ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // トランザクション初期化
    this.rollback();

    // poplistの初期化実行
    this.initPopList(pvDisplayMode);

    // 画面と紐付く全てのVOインスタンスの取得
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,true
    );

    // プロファイルの取得
    String defaultViewLine
      = txt.getProfile(XxcsoPvCommonConstants.XXCSO1_IB_PV_D_VIEW_LINES);
    if ( defaultViewLine == null || "".equals(defaultViewLine.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoPvCommonConstants.XXCSO1_IB_PV_D_VIEW_LINES
        );
    }

    // ******************************
    // 画面設定用VOへの値の設定
    // ******************************
    // 一般プロパティ
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.createRow();
    // 検索条件AND/OR条件指定の初期値を設定
    pvDefVoRow.setExtractPatternCode(XxcsoPvCommonConstants.EXTRACT_AND);
    pvDefVoRow.setViewSize(defaultViewLine);
    pvDefVo.insertRow(pvDefVoRow);

    // 表示列(新規作成)インスタンス
    XxcsoDispayColumnInitVOImpl dispClmInitVo  = getXxcsoDispayColumnInitVO1();
    if ( dispClmInitVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoDispayColumnInitVOImpl");
    }
    dispClmInitVo.initQuery(pvDisplayMode);

    // 表示列(新規作成)行インスタンス
    XxcsoDispayColumnInitVORowImpl dispClmInitVoRow
      = (XxcsoDispayColumnInitVORowImpl) dispClmInitVo.first();
    if ( dispClmInitVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDispayColumnInitVORowImpl");
    }

    // 表示列(新規作成)で取得した分画面用VOへ設定
    while (dispClmInitVoRow != null)
    {
      XxcsoDisplayColumnSumVORowImpl dispClmSumVoRow
        = (XxcsoDisplayColumnSumVORowImpl) dispClmSumVo.createRow();

      dispClmSumVoRow.setDescription( dispClmInitVoRow.getDescription() );
      dispClmSumVoRow.setLookupCode( dispClmInitVoRow.getLookupCode() );

      dispClmSumVo.last();
      dispClmSumVo.next();
      dispClmSumVo.insertRow(dispClmSumVoRow);

      dispClmInitVoRow = (XxcsoDispayColumnInitVORowImpl) dispClmInitVo.next();

    }

    // ソート設定 表示用状態設定処理
    this.createSortColumn(sortClmFullVo);

    // 検索条件(新規作成)インスタンス
    XxcsoPvExtractTermSumVOImpl extTermSumVo = getXxcsoPvExtractTermSumVO1();
    if ( extTermSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermSumVOImpl");
    }
    extTermSumVo.initQuery(pvDisplayMode);

    // 検索条件(新規作成)行インスタンス
    XxcsoPvExtractTermSumVORowImpl extTermSumVoRow
      = (XxcsoPvExtractTermSumVORowImpl) extTermSumVo.first();
    if ( extTermSumVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermSumVORowImpl");
    }

    // 検索条件(新規作成)VOで取得した分画面用VOへ設定
    while (extTermSumVoRow != null)
    {
      XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

      // 行の表示属性設定を行う
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermSumVoRow.getLookupCode()
       ,null
       ,null
       ,null
       ,null
      );
       
      extTermFullVo.last();
      extTermFullVo.next();
      extTermFullVo.insertRow(extTermFullVoRow);

      extTermSumVoRow = (XxcsoPvExtractTermSumVORowImpl) extTermSumVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 初期化処理(複製)
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索使用モード
   *****************************************************************************
   */
  public Boolean initCopyDetails(
     String viewId
    ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // トランザクション初期化
    this.rollback();

    // poplistの初期化実行
    this.initPopList(pvDisplayMode);

    // 画面と紐付く全てのVOインスタンスの取得
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,true
    );

    // ******************************
    // 画面設定用VOへの値の設定
    // ******************************
    // 複製用インスタンスの取得
    // 一般プロパティ
    XxcsoPvDefFullVOImpl pvDefCopyVo = getXxcsoPvDefCopyVO();
    if ( pvDefCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefCopyVO");
    }

    // 表示列
    XxcsoPvViewColumnFullVOImpl viewClmCopyVo = getXxcsoPvViewColumnCopyVO();
    if ( viewClmCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    // ソート設定
    XxcsoPvSortColumnFullVOImpl sortClmCopyVo = getXxcsoPvSortColumnCopyVO();
    if ( sortClmCopyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnCopyVO");
    }
    sortClmCopyVo.initQuery(pvDisplayMode);

    // 検索条件
    XxcsoPvExtractTermFullVOImpl extTermCopyVo = getXxcsoPvExtractTermCopyVO();
    if ( extTermCopyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermCopyVO");
    }
    extTermCopyVo.initQuery(pvDisplayMode);

    // ソート、検索条件のinitQuery完了後、一般プロパティのinitQuery実施
    pvDefCopyVo.initQuery(viewId, false);
    XxcsoPvDefFullVORowImpl pvDefCopyVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefCopyVo.first();
    if (pvDefCopyVoRow == null)
    {
      return Boolean.FALSE;
    }
    // ソート条件
    // 未設定状態がありうるためrowのnullチェックは行わない
    XxcsoPvSortColumnFullVORowImpl sortClmCopyVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortClmCopyVo.first();

    // 検索条件
    XxcsoPvExtractTermFullVORowImpl extTermCopyVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermCopyVo.first();
    if (extTermCopyVoRow == null)
    {
      return Boolean.FALSE;
    }


    // ****************************
    // 複製→画面設定用VOへ値の設定
    // ****************************

    // 一般プロパティ
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.createRow();

    pvDefVoRow.setViewName(
      pvDefCopyVoRow.getViewName() + XxcsoPvCommonConstants.ADD_VIEW_NAME_COPY
    );
    pvDefVoRow.setViewSize(           pvDefCopyVoRow.getViewSize() );
    pvDefVoRow.setDefaultFlag(        pvDefCopyVoRow.getDefaultFlag() );
    pvDefVoRow.setViewOpenCode(       pvDefCopyVoRow.getViewOpenCode() );
    pvDefVoRow.setDescription(        pvDefCopyVoRow.getDescription() );
    pvDefVoRow.setExtractPatternCode( pvDefCopyVoRow.getExtractPatternCode() );
    pvDefVo.insertRow(pvDefVoRow);

    // ソート設定
    while( sortClmCopyVoRow != null )
    {
      XxcsoPvSortColumnFullVORowImpl sortClmFullVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortClmFullVo.createRow();
      sortClmFullVoRow.setColumnCode(sortClmCopyVoRow.getColumnCode());
      sortClmFullVoRow.setSortDirectionCode(
				sortClmCopyVoRow.getSortDirectionCode()
      );

      sortClmFullVo.last();
      sortClmFullVo.next();
      sortClmFullVo.insertRow(sortClmFullVoRow);
      sortClmCopyVoRow = (XxcsoPvSortColumnFullVORowImpl) sortClmCopyVo.next();
    }

    // ソート設定 表示用状態設定処理
    this.createSortColumn(sortClmFullVo);

    // 検索条件
    while(extTermCopyVoRow != null) 
    {
      XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

      // 行の表示属性設定を行う
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermCopyVoRow.getColumnCode()
       ,extTermCopyVoRow.getExtractMethodCode()
       ,extTermCopyVoRow.getExtractTermText()
       ,extTermCopyVoRow.getExtractTermNumber()
       ,extTermCopyVoRow.getExtractTermDate()
      );

      extTermFullVo.last();
      extTermFullVo.next();
      extTermFullVo.insertRow(extTermFullVoRow);

      extTermCopyVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermCopyVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");

    return Boolean.TRUE;

  }

  /*****************************************************************************
   * 初期化処理(更新)
   * @param viewId        ビューID
   * @param pvDisplayMode 汎用検索使用モード
   *****************************************************************************
   */
  public Boolean initUpdateDetails(
     String viewId
    ,String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // トランザクション初期化
    this.rollback();

    // poplistの初期化実行
    this.initPopList(pvDisplayMode);

    // 画面と紐付く全てのVOインスタンスの取得
    XxcsoPvDefFullVOImpl         pvDefVo       = getXxcsoPvDefFullVO1();
    XxcsoEnableColumnSumVOImpl   enableClmSumVo = getXxcsoEnableColumnSumVO1();
    XxcsoDisplayColumnSumVOImpl  dispClmSumVo  = getXxcsoDisplayColumnSumVO1();
    XxcsoPvViewColumnFullVOImpl  viewClmFullVo = getXxcsoPvViewColumnFullVO1();
    XxcsoPvSortColumnFullVOImpl  sortClmFullVo = getXxcsoPvSortColumnFullVO1();
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    this.initAllInstance(
      pvDefVo
     ,enableClmSumVo
     ,dispClmSumVo
     ,viewClmFullVo
     ,sortClmFullVo
     ,extTermFullVo
     ,viewId
     ,pvDisplayMode
     ,false
    );

    if ( pvDefVo.first() == null)
    {
      return Boolean.FALSE;
    }

    // ソート設定 表示用状態設定処理
    this.createSortColumn(sortClmFullVo);

    // 検索条件行インスタンス取得
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.first();
    if ( extTermFullVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVORowImpl");
    }
  
    // 取得分繰り返し
    while (extTermFullVoRow != null)
    {
      // 行の表示属性設定を行う
      this.setAttributeExtract(
        extTermFullVoRow
       ,extTermFullVoRow.getColumnCode()
       ,extTermFullVoRow.getExtractMethodCode()
       ,extTermFullVoRow.getExtractTermText()
       ,extTermFullVoRow.getExtractTermNumber()
       ,extTermFullVoRow.getExtractTermDate()
      );

      extTermFullVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.next();
    }

    XxcsoUtils.debug(txt, "[END]");

    return Boolean.TRUE;
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
   * 適用および検索実行ボタン押下時処理
   * @param list shuttleリージョンtrailingのvalue値
   * @return viewId
   *****************************************************************************
   */
  public String handleAppliAndSearchButton(ArrayList list)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 登録内容情報設定処理
    String viewId = this.setPvDefItemFull( list );

    XxcsoUtils.debug(txt, "[END]");

    return viewId;
  }

  /*****************************************************************************
   * 摘要ボタン押下時処理
   * @param list shuttleリージョンtrailingのvalue値
   *****************************************************************************
   */
  public void handleApplicationButton(ArrayList list)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 登録内容情報設定処理(戻り値無視)
    this.setPvDefItemFull( list );

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 追加ボタン押下時処理
   *****************************************************************************
   */
  public void handleAddtionButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // プロファイルオプション取得
    String maxFetchSize = txt.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxFetchSize == null || "".equals(maxFetchSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    // 一般プロパティインスタンス
    XxcsoPvDefFullVOImpl pvDefFullVo = getXxcsoPvDefFullVO1();
    if ( pvDefFullVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }

    // 一般プロパティ行インスタンス
    XxcsoPvDefFullVORowImpl pvDefFullVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefFullVo.first();
    if ( pvDefFullVoRow == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    // 検索条件インスタンス取得
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }

    // 検索条件設定設定上限チェック
    if (Integer.parseInt(maxFetchSize) <= extTermFullVo.getRowCount())
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
          ,XxcsoConstants.TOKEN_OBJECT
          ,XxcsoPvCommonConstants.MSG_EXTRACT_COLUMN
          ,XxcsoConstants.TOKEN_MAX_SIZE
          ,maxFetchSize
        );
    }

    // 検索条件行インスタンス作成
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.createRow();

    // 行の表示属性設定を行う
    this.setAttributeExtract(
      extTermFullVoRow
      ,pvDefFullVoRow.getAddColumn()
      ,null
      ,null
      ,null
      ,null
    );
    extTermFullVo.last();
    extTermFullVo.next();
    extTermFullVo.insertRow(extTermFullVoRow);

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * 削除ボタン押下時処理
   *****************************************************************************
   */
  public void handleDeleteButton()
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // 検索条件インスタンス取得
    XxcsoPvExtractTermFullVOImpl extTermFullVo = getXxcsoPvExtractTermFullVO1();
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    // 検索条件行インスタンス作成
    XxcsoPvExtractTermFullVORowImpl extTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.first();
    // rowが存在しない場合に削除ボタンを押下されることはありえない
    if ( extTermFullVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVORowImpl");
    }

    boolean isDelete = false;

    while ( extTermFullVoRow != null)
    {
      if ("Y".equals( extTermFullVoRow.getSelectFlag() ) )
      {
        extTermFullVo.removeCurrentRow();
        isDelete = true;
      }
      extTermFullVoRow = (XxcsoPvExtractTermFullVORowImpl) extTermFullVo.next();
    }

    if ( !isDelete )
    {
      // 検索条件未選択エラー
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00133
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoPvCommonConstants.MSG_RECORD
        );
    }
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
   * 画面登録用インスタンス初期化処理
   * @param pvDefVo        一般プロパティインスタンス
   * @param enableClmSumVo 使用可能列インスタンス
   * @param dispClmSumVo   表示列(表示用)インスタンス
   * @param viewClmFullVo  表示列(登録用)インスタンス
   * @param sortClmFullVo  ソート列インスタンス
   * @param extTermFullVo  検索条件列インスタンス
   * @param viewId         ビューID
   * @param pvDisplayMode  汎用検索使用モード
   * @param isCopy         true:新規作成、複製 false:更新
   *****************************************************************************
   */
  private void initAllInstance(
    XxcsoPvDefFullVOImpl         pvDefVo
   ,XxcsoEnableColumnSumVOImpl   enableClmSumVo
   ,XxcsoDisplayColumnSumVOImpl  dispClmSumVo
   ,XxcsoPvViewColumnFullVOImpl  viewClmFullVo
   ,XxcsoPvSortColumnFullVOImpl  sortClmFullVo
   ,XxcsoPvExtractTermFullVOImpl extTermFullVo
   ,String viewId
   ,String pvDisplayMode
   ,boolean isCopy
  )
  {

    // 一般プロパティのインスタンス取得
    if (pvDefVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    pvDefVo.initQuery(viewId, isCopy);

    // 使用可能列インスタンス取得
    if ( enableClmSumVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEnableColumnSumVOImpl");
    }
    enableClmSumVo.initQuery(viewId, pvDisplayMode);
    enableClmSumVo.first();

    // 表示列インスタンス取得（表示用）
    if ( dispClmSumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDisplayColumnSumVOImpl");
    }
    dispClmSumVo.initQuery(viewId, pvDisplayMode);
    dispClmSumVo.first();

    // 表示列インスタンス取得（登録用）
    // ※登録前にここで初期化
    if ( viewClmFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    // ソート設定インスタンス取得
    if ( sortClmFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    sortClmFullVo.initQuery(pvDisplayMode);

    // 検索条件インスタンス取得
    if ( extTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    extTermFullVo.initQuery(pvDisplayMode);

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
   * poplist初期化処理
   * @param pvDisplayMode 汎用検索使用モード
   *****************************************************************************
   */
  private void initPopList(
    String pvDisplayMode
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // ****************************************
    // *****Lookupの初期化*********************
    // ****************************************
    // *****一般指定リージョン
    // 表示行数
    XxcsoLookupListVOImpl viewSizeLookupVo = getXxcsoViewSizeLookupListVO();
    if ( viewSizeLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoViewSizeLookupListVO");
    }
    viewSizeLookupVo.initQuery("XXCSO1_IB_PV_VIEW_LINES", null, "1");
    viewSizeLookupVo.executeQuery();

    // *****ソート設定リージョン
    // 列名
    XxcsoLookupListVOImpl columnNameLookupVo = getXxcsoColumnNameLookupVO();
    if ( columnNameLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoColumnNameLookupVO");
    }
    StringBuffer sbWhere1 = new StringBuffer(50);
    sbWhere1
      .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
      .append(", 1) = '1'")
    ;
    columnNameLookupVo.initQuery(
      "XXCSO1_IB_PV_COLUMN_DEF"
      ,new String(sbWhere1)
      ,"TO_NUMBER(lookup_code)"
    );
    columnNameLookupVo.executeQuery();

    // ソート順
    XxcsoLookupListVOImpl sortDirectionLookupVo
      = getXxcsoSortDirectionLookupVO();
    if ( sortDirectionLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSortDirectionLookupVO");
    }
    sortDirectionLookupVo.initQuery(
      "XXCSO1_IB_PV_SORT_TYPE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    sortDirectionLookupVo.executeQuery();


    // *****検索条件リージョン
    // 条件追加
    XxcsoLookupListVOImpl addConditionLookupVo = getXxcsoAddConditionLookupVO();
    if ( addConditionLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAddConditionLookupVO");
    }
    StringBuffer sbWhere2 = new StringBuffer(100);
    sbWhere2
      .append("      SUBSTRB(attribute1, ").append(pvDisplayMode)
      .append(", 1) = '1'")
      .append("AND   SUBSTRB(attribute3, ").append(pvDisplayMode)
      .append(", 1) = '1'")
    ;

    addConditionLookupVo.initQuery(
      "XXCSO1_IB_PV_COLUMN_DEF"
      ,new String(sbWhere2)
      ,"TO_NUMBER(lookup_code)"
    );
    addConditionLookupVo.executeQuery();

    // 抽出方法(テキスト(文字))
    XxcsoLookupListVOImpl modeTextLookupVo = getXxcsoModeTextLookupVO();
    if ( modeTextLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeTextLookupVO");
    }
    modeTextLookupVo.initQuery(
      "XXCSO1_IB_PV_VARCHAR2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeTextLookupVo.executeQuery();

    // 抽出方法(テキスト(数字))
    XxcsoLookupListVOImpl modeNumberLookupVo = getXxcsoModeNumberLookupVO();
    if ( modeNumberLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeDateLookupVO");
    }
    modeNumberLookupVo.initQuery(
      "XXCSO1_IB_PV_NUMBER"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeNumberLookupVo.executeQuery();

    // 抽出方法(日付)
    XxcsoLookupListVOImpl modeDateLookupVo = getXxcsoModeDateLookupVO();
    if ( modeDateLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeDateLookupVO");
    }
    modeDateLookupVo.initQuery(
      "XXCSO1_IB_PV_DATE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeDateLookupVo.executeQuery();

    // 抽出方法(LOV)
    XxcsoLookupListVOImpl modeLovLookupVo = getXxcsoModeLovLookupVO();
    if ( modeLovLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModeLovLookupVO");
    }
    modeLovLookupVo.initQuery(
      "XXCSO1_IB_PV_MATCH"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modeLovLookupVo.executeQuery();

    // 抽出方法(ポップリスト)
    XxcsoLookupListVOImpl modePoplistLookupVo = getXxcsoModePoplistLookupVO();
    if ( modePoplistLookupVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoModePoplistLookupVO");
    }
    modePoplistLookupVo.initQuery(
      "XXCSO1_IB_PV_MATCH"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    modePoplistLookupVo.executeQuery();

    // AND/OR条件指定
    XxcsoLookupListVOImpl andOrLookupVo = getXxcsoAndOrLookupVO();
    if (andOrLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAndOrLookupVO");
    }
    andOrLookupVo.initQuery(
      "XXCSO1_IB_PV_AND_OR"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    andOrLookupVo.executeQuery();

    // 機器区分 where020
    XxcsoVendorTypeListVOImpl vendorTypeListVo = getXxcsoVendorTypeListVO1();
    if (vendorTypeListVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoVendorTypeListVO1");
    }

    // 機器状態1 where060
    XxcsoLookupListVOImpl where060LookupVo = getXxcsoWhere060LookupVO();
    if (where060LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere060LookupVO");
    }
    where060LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN1"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where060LookupVo.executeQuery();

    // 機器状態2 where070
    XxcsoLookupListVOImpl where070LookupVo = getXxcsoWhere070LookupVO();
    if (where070LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere070LookupVO");
    }
    where070LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where070LookupVo.executeQuery();

    // 機器状態3 where080
    XxcsoLookupListVOImpl where080LookupVo = getXxcsoWhere080LookupVO();
    if (where080LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere080LookupVO");
    }
    where080LookupVo.initQuery(
      "XXCSO1_CSI_JOTAI_KBN3"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where080LookupVo.executeQuery();

    // メーカーコード  where150
    XxcsoLookupListVOImpl where150LookupVo = getXxcsoWhere150LookupVO();
    if (where150LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere150LookupVO");
    }
    where150LookupVo.initQuery(
      "XXCSO_CSI_MAKER_CODE"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where150LookupVo.executeQuery();

    // 設置業種区分  where220
    XxcsoConsciousLookupListVOImpl where220LookupVo
      = getXxcsoWhere220LookupVO();
    if (where220LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere220LookupVO");
    }
    where220LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_GYOTAI_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where220LookupVo.executeQuery();

    // 特殊機1 where300
    XxcsoLookupListVOImpl where300LookupVo = getXxcsoWhere300LookupVO();
    if (where300LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere300LookupVO");
    }
    where300LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
     );
    where300LookupVo.executeQuery();

    // 特殊機2 where310
    XxcsoLookupListVOImpl where310LookupVo = getXxcsoWhere310LookupVO();
    if (where310LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere310LookupVO");
    }
    where310LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where310LookupVo.executeQuery();

    // 特殊機3 where320
    XxcsoLookupListVOImpl where320LookupVo = getXxcsoWhere320LookupVO();
    if (where320LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere320LookupVO");
    }
    where320LookupVo.initQuery(
      "XXCSO_CSI_TOKUSHUKI"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where320LookupVo.executeQuery();

    // リース状態(再リース)  where510
    XxcsoLookupListVOImpl where510LookupVo = getXxcsoWhere510LookupVO();
    if (where510LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere510LookupVO");
    }
    where510LookupVo.initQuery(
      "XXCFF1_OBJECT_STATUS"
     ,"attribute1 = '1'"
     ,"TO_NUMBER(lookup_code)"
    );
    where510LookupVo.executeQuery();

    // 設置場所 where550
    XxcsoConsciousLookupListVOImpl where550LookupVo
      = getXxcsoWhere550LookupVO();
    if (where550LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere550LookupVO");
    }
    where550LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_VD_SECCHI_BASYO"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where550LookupVo.executeQuery();

    // 業態(小分類) where560
    XxcsoConsciousLookupListVOImpl where560LookupVo
      = getXxcsoWhere560LookupVO();
    if (where560LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere560LookupVO");
    }
    where560LookupVo.initQuery(
      "XXCMM"
     ,"AU"
     ,"XXCMM_CUST_GYOTAI_SHO"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where560LookupVo.executeQuery();

    // 最終設置区分 where600
    XxcsoLookupListVOImpl where600LookupVo = getXxcsoWhere600LookupVO();
    if (where600LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere600LookupVO");
    }
    where600LookupVo.initQuery(
      "XXCSO1_CSI_JOB_KBN2"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where600LookupVo.executeQuery();

    // 最終設置進捗 where610
    XxcsoLookupListVOImpl where610LookupVo = getXxcsoWhere610LookupVO();
    if (where610LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere610LookupVO");
    }
    where610LookupVo.initQuery(
      "XXCSO1_CSI_SINTYOKU_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where610LookupVo.executeQuery();

    // 最終設備内容 where620
    XxcsoLookupListVOImpl where620LookupVo = getXxcsoWhere620LookupVO();
    if (where620LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere620LookupVO");
    }
    where620LookupVo.initQuery(
      "XXCSO1_SAGYO_LEVEL"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where620LookupVo.executeQuery();

    // 最終作業区分 where660
    XxcsoLookupListVOImpl where660LookupVo = getXxcsoWhere660LookupVO();
    if (where660LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere660LookupVO");
    }
    where660LookupVo.initQuery(
      "XXCSO1_CSI_JOB_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where660LookupVo.executeQuery();

    // 最終作業進捗 where670
    XxcsoLookupListVOImpl where670LookupVo = getXxcsoWhere670LookupVO();
    if (where670LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere670LookupVO");
    }
    where670LookupVo.initQuery(
      "XXCSO1_CSI_SINTYOKU_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where670LookupVo.executeQuery();

    // 転売廃棄状況 where730
    XxcsoLookupListVOImpl where730LookupVo = getXxcsoWhere730LookupVO();
    if (where730LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere730LookupVO");
    }
    where730LookupVo.initQuery(
      "XXCSO1_CSI_TENHAI_FLG"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where730LookupVo.executeQuery();

    // 転売完了区分 where740
    XxcsoLookupListVOImpl where740LookupVo = getXxcsoWhere740LookupVO();
    if (where740LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere740LookupVO");
    }
    where740LookupVo.initQuery(
      "XXCSO1_CSI_KANRYO_KBN"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where740LookupVo.executeQuery();

    // メーカー名 where770
    XxcsoLookupListVOImpl where770LookupVo = getXxcsoWhere770LookupVO();
    if (where770LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere770LookupVO");
    }
    where770LookupVo.initQuery(
      "XXCSO_CSI_MAKER_CODE"
      ,null
      ,"TO_NUMBER(lookup_code)"
    );
    where150LookupVo.executeQuery();

    // 安全設置基準 where780
    XxcsoLookupListVOImpl where780LookupVo = getXxcsoWhere780LookupVO();
    if (where780LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere780LookupVO");
    }
    where780LookupVo.initQuery(
      "XXCSO1_CSI_SAFETY_LEVEL"
     ,null
     ,"TO_NUMBER(lookup_code)"
    );
    where780LookupVo.executeQuery();

// 2009/04/24 [ST障害T1_634] Add Start
    XxcsoLookupListVOImpl where790LookupVo = getXxcsoWhere790LookupVO();
    if (where790LookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoWhere790LookupVO");
    }
    where790LookupVo.initQuery(
      "XXCSO1_OP_REQUEST_FLAG"
     ,null
     ,"lookup_code"
    );
    where790LookupVo.executeQuery();
// 2009/04/24 [ST障害T1_634] Add End

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * ソート設定 行作成
   * @param XxcsoPvSortColumnFullVOImpl ソート表示インスタンス
   *****************************************************************************
   */
  private void createSortColumn(XxcsoPvSortColumnFullVOImpl sortColumnVo)
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    // insert判定フラグ
    boolean isInsert = false;

    XxcsoPvSortColumnFullVORowImpl sortColumnVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.first();
    if ( sortColumnVoRow == null )
    {
      sortColumnVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.createRow();
      isInsert = true;
    }

    // ソート設定行インスタンスを生成し空白行を挿入
    for (int i = 0; i < XxcsoPvCommonConstants.SORT_SETTING_SIZE; i++)
    {

      if (sortColumnVoRow == null)
      {
        isInsert = true;

        sortColumnVoRow
          = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.createRow();
      }

      // 行見出しの作成
      StringBuffer sb = new StringBuffer(10);
      sb.append( XxcsoPvCommonConstants.SORT_LINE_CAPTION1 );
      sb.append( String.valueOf( i + 1 ) );
      sb.append( XxcsoPvCommonConstants.SORT_LINE_CAPTION2 );

      // 値の設定
      sortColumnVoRow.setLineCaption(new String(sb));

      if ( isInsert )
      {
        sortColumnVo.last();
        sortColumnVo.next();
        sortColumnVo.insertRow(sortColumnVoRow);
      } 
      sortColumnVoRow = (XxcsoPvSortColumnFullVORowImpl) sortColumnVo.next();
    }

    XxcsoUtils.debug(txt, "[End]");
  }

  /*****************************************************************************
   * 抽出条件行属性設定
   * @param extractRow  行インスタンス
   * @param lookupCode  クイックコード
   *****************************************************************************
   */
  private void setAttributeExtract(
    XxcsoPvExtractTermFullVORowImpl extractRow
   ,String                         columnCode
   ,String                         mehodCode
   ,String                         termText
   ,String                         termNumber
   ,Date                           termDate
  )
  {
    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    for (int i = 0; i < XxcsoPvCommonConstants.EXTRACT_SIZE; i++)
    {
      // Attribute設定用文字列の生成
      String attStr = String.valueOf( ( i + 1 ) * 10 );

      // 2桁時0埋め対応
      if (attStr.length() == 2)
      {
        attStr = "0" + attStr;
      }
      if ( attStr.equals(columnCode) )
      {
        extractRow.setColumnCode(columnCode);          // 列コード
        extractRow.setExtractMethodCode(mehodCode);    // 抽出方法コード
        if ( !isNull(termText) )
        {
          extractRow.setExtractTermText(termText);     // 抽出条件(文字/LOV)
        }
        if ( !isNull(termNumber) )
        {
          extractRow.setExtractTermNumber(termNumber); // 抽出条件(数字)
        }
        if ( !isNull(termDate) )
        {
          extractRow.setExtractTermDate(termDate);     // 抽出条件(日付)
        }
        // レンダリング=true
        extractRow.setAttribute(
          XxcsoPvCommonConstants.EXTRACT_RENDER + attStr
         ,Boolean.TRUE
        );

        // 列コード=拠点コード時の初期値設定
        if (
          ( XxcsoPvCommonConstants.EXTRACT_VALUE_010.equals(columnCode) ) &&
          ( isNull(termText) )
        )
        {
          extractRow.setExtractTermText(this.getSelfBaseCode());  
        }
      } else {

        // レンダリング=false
        extractRow.setAttribute(
          XxcsoPvCommonConstants.EXTRACT_RENDER + attStr
         ,Boolean.FALSE
        );
      }
    }
    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * 登録内容設定処理
   * @param  trailingList shuttleリージョンtrailingのvalue値
   * @return 登録／複製／更新時のビューID 
   *****************************************************************************
   */
  private String setPvDefItemFull(ArrayList trailingList)
  {

    OADBTransaction txt = getOADBTransaction();

    XxcsoUtils.debug(txt, "[START]");

    String tokenValue = ""; // 成功時の付加メッセージ(登録or更新)
    String updViewId = "";  // 更新ビューID 
    String viewName = null; // ビュー名

    // **************
    // ビュー名の取得
    // **************
    // 一般プロパティ
    XxcsoPvDefFullVOImpl pvDefVo = getXxcsoPvDefFullVO1();
    if (pvDefVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVOImpl");
    }
    XxcsoPvDefFullVORowImpl pvDefVoRow
      = (XxcsoPvDefFullVORowImpl) pvDefVo.first();
    if (pvDefVoRow == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefFullVORowImpl");
    }

    viewName = pvDefVoRow.getViewName();
    // ビュー名入力チェック処理
    if ( viewName == null || "".equals(viewName.trim()) )
    {
      // ビュー名未入力エラー
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00005
         ,XxcsoConstants.TOKEN_COLUMN
         ,XxcsoPvCommonConstants.MSG_VIEW_NAME
        );
    }


    // 登録・複製・更新での処理分岐
    // 更新の場合
    if (pvDefVoRow.getViewId().longValue() > 0) 
    {
      tokenValue = XxcsoConstants.TOKEN_VALUE_UPDATE;
      updViewId = pvDefVoRow.getViewId().toString();
    }
    // 登録・複製の場合
    else
    {
      tokenValue = XxcsoConstants.TOKEN_VALUE_REGIST;

      // 表示有無フラグの設定
      pvDefVoRow.setViewOpenCode(XxcsoPvCommonConstants.VIEW_OPEN_CODE_OPEN);

    }

    // デフォルトフラグONの場合
    if (XxcsoPvCommonConstants.DEFAULT_FLAG_YES.equals(
          pvDefVoRow.getDefaultFlag())
       )
    {
      // 他のデフォルトフラグをOFFに設定する
      this.updDefaultFlg(updViewId);
    }

    // **************************
    // 表示列リージョン設定順設定
    // **************************
    int listSize = trailingList.size();
    if (listSize == 0)
    {
      // 表示列未設定エラー
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00494);
    }

    // 表示列(登録用)インスタンス取得
    XxcsoPvViewColumnFullVOImpl viewColumnFullVo
      = getXxcsoPvViewColumnFullVO1();
    if ( viewColumnFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvViewColumnFullVOImpl");
    }

    int setupNumberView = 1;

    XxcsoPvViewColumnFullVORowImpl viewColumnFullVoRow
      = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.first();

    boolean isCleate = false;

    // 画面の内容で順に1から設定
    for (int i = 0; i < listSize; i++)
    {
      isCleate = false;

      if (viewColumnFullVoRow == null)
      {
        viewColumnFullVoRow
          = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.createRow();
        isCleate = true;
      }

      viewColumnFullVoRow.setSetupNumber(new Number(setupNumberView++));
      viewColumnFullVoRow.setColumnCode( (String) trailingList.get(i));

      if ( isCleate )
      {
        viewColumnFullVo.last();
        viewColumnFullVo.next();
        viewColumnFullVo.insertRow(viewColumnFullVoRow);
      }

      viewColumnFullVoRow
        = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.next();
    }

    // 表示列初期表示時オブジェクトにまだデータがある場合は削除する
    while ( viewColumnFullVoRow != null )
    {
      viewColumnFullVo.removeCurrentRow();
      viewColumnFullVoRow
        = (XxcsoPvViewColumnFullVORowImpl) viewColumnFullVo.next();
    }

    // ******************************
    // 検索条件列リージョン設定判定
    // ******************************
    XxcsoPvExtractTermFullVOImpl extractTermFullVo
      = getXxcsoPvExtractTermFullVO1();
    if ( extractTermFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractTermFullVOImpl");
    }
    XxcsoPvExtractTermFullVORowImpl extractTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.first();

    boolean isSetting = false; // 設定判定用フラグ
    while ( extractTermFullVoRow != null )
    {
      String extColumnCode = extractTermFullVoRow.getColumnCode();
      String extMethodCode = extractTermFullVoRow.getExtractMethodCode();
      String extTermText   = extractTermFullVoRow.getExtractTermText();
      // 拠点・物件・顧客のコードのいずれかに値が設定されているかチェック
      if ( XxcsoPvCommonConstants.EXTRACT_VALUE_010.equals(extColumnCode)
        || XxcsoPvCommonConstants.EXTRACT_VALUE_030.equals(extColumnCode)
        || XxcsoPvCommonConstants.EXTRACT_VALUE_090.equals(extColumnCode)
      )
      {
        if ( !isNull(extMethodCode) && !isNull(extTermText) ) 
        {
          // 何か一つでも設定されていればフラグをtrueに設定
          isSetting = true;
        }
      }
      extractTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.next();

    }

    if ( !isSetting )
    {
      // 検索条件設定不足エラー
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00455);
    }

    // ****************************
    // ソート列リージョン設定順設定
    // ****************************
    XxcsoPvSortColumnFullVOImpl sortColumnFullVo
      = getXxcsoPvSortColumnFullVO1();
    if ( sortColumnFullVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvSortColumnFullVOImpl");
    }
    XxcsoPvSortColumnFullVORowImpl sortColumnFullVoRow
      = (XxcsoPvSortColumnFullVORowImpl) sortColumnFullVo.first();

    int setupNumberSort = 1;

    // 画面の内容で順に1から設定
    while ( sortColumnFullVoRow != null )
    {
      String columnCode = sortColumnFullVoRow.getColumnCode();
      String sortDirectionCode = sortColumnFullVoRow.getSortDirectionCode();
      // ソート列名とソート順のいずれかが設定されていない場合
      if ( isNull(columnCode) || isNull(sortDirectionCode) ) 
      {
        // 対象行を削除し、次行へ
        sortColumnFullVo.removeCurrentRow();
      }
      else
      {
        sortColumnFullVoRow.setSetupNumber(new Number(setupNumberSort++));
      }

      sortColumnFullVoRow
        = (XxcsoPvSortColumnFullVORowImpl) sortColumnFullVo.next();
    }

    // ******************************
    // 検索条件列リージョン設定順設定
    // ******************************
    extractTermFullVoRow
      = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.first();
    
    int setupNumberExt = 1;
    // 画面の内容で順に1から設定
    while ( extractTermFullVoRow != null )
    {
      String extMethodCode = extractTermFullVoRow.getExtractMethodCode();
      String extTermText   = extractTermFullVoRow.getExtractTermText();
      String extTermNumber = extractTermFullVoRow.getExtractTermNumber();
      Date extTermDate   = extractTermFullVoRow.getExtractTermDate();
      // 抽出列名と抽出方法のいずれかが設定されていない場合
      if ( isNull(extMethodCode) || 
         ( isNull(extTermText) && isNull(extTermNumber) &&
           isNull(extTermDate)
         )
      )
      {
        // 対象行を削除
        extractTermFullVo.removeCurrentRow();
      }
      else
      {
        extractTermFullVoRow.setSetupNumber(new Number(setupNumberExt++));
      }

      extractTermFullVoRow
        = (XxcsoPvExtractTermFullVORowImpl) extractTermFullVo.next();

    }

    // 保存処理を実行します。
    this.commit();

    // 払い出されたビューIDを退避
    String targetViewId = pvDefVoRow.getViewId().toString();

    // 成功メッセージの設定
    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,viewName
         ,XxcsoConstants.TOKEN_ACTION
         ,tokenValue
        );

    XxcsoUtils.debug(txt, "[END]");

    return targetViewId;
  }
  
  /*****************************************************************************
   * デフォルトフラグ更新処理
   * @param  viewId    ビューID
   *****************************************************************************
   */
  private void updDefaultFlg(String viewId)
  {
    // 現在デフォルトフラグが設定されている汎用検索テーブルを取得
    XxcsoPvDefUpdDfltFlgVOImpl pvDefDefltFlgVo = getXxcsoPvDefUpdDfltFlgVO();
    if ( pvDefDefltFlgVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoPvDefUpdDfltFlgImpl");
    }
    pvDefDefltFlgVo.initQuery(viewId);

    XxcsoPvDefUpdDfltFlgVORowImpl pvDefDefltFlgVoRow
      = (XxcsoPvDefUpdDfltFlgVORowImpl) pvDefDefltFlgVo.first();
    if ( pvDefDefltFlgVoRow == null )
    {
      // rowが存在しない=0件とみなし、処理終了
      return;
    }

    while (pvDefDefltFlgVoRow != null)
    {
      // "Y"に設定されているものは全て"N"にする
      pvDefDefltFlgVoRow.setDefaultFlag(XxcsoPvCommonConstants.DEFAULT_FLAG_NO);
      pvDefDefltFlgVoRow
        = (XxcsoPvDefUpdDfltFlgVORowImpl) pvDefDefltFlgVo.next();
    }

    return;
  }
  
  /*****************************************************************************
   * 自拠点コード取得処理
   * @return  自拠点コード
   * @throw   OAException
   *****************************************************************************
   */
  private String getSelfBaseCode()
  {
    XxcsoPvExtractDispInitVOImpl extDispInitVo = getXxcsoPvExtractDispInitVO();
    if ( extDispInitVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVOImpl");
    }
    extDispInitVo.executeQuery();

    XxcsoPvExtractDispInitVORowImpl extDispInitVoRow
      = (XxcsoPvExtractDispInitVORowImpl) extDispInitVo.first();
    if ( extDispInitVoRow == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoPvExtractDispInitVORowImpl");
    }
    return extDispInitVoRow.getBaseCode();
    
  }

  /*****************************************************************************
   * Nullチェック
   * @param  obj    Nullチェックを行うオブジェクト
   * @return true   Null(Stringの場合はnullまたは空文字)
   *         false  not Null
   *****************************************************************************
   */
  private boolean isNull(Object obj)
  {
    if (obj instanceof String)
    {
      if (obj == null || "".equals(obj.toString()))
      {
        return true;
      }
    }
    else
    {
      if (obj == null)
      {
        return true;
      }
    }
    return false;
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso012001j.server", "xxcsoPersonalizedViewRegistAMLocal");
  }


  /**
   * 
   * Container's getter for XxcsoViewSizeLookupListVO
   */
  public XxcsoLookupListVOImpl getXxcsoViewSizeLookupListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoViewSizeLookupListVO");
  }

  /**
   * 
   * Container's getter for XxcsoAddConditionLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoAddConditionLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAddConditionLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeTextLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeTextLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeTextLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeDateLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeDateLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeDateLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeLovLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeLovLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeLovLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModePoplistLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModePoplistLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModePoplistLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoModeNumberLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoModeNumberLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoModeNumberLookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoColumnNameLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoColumnNameLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoColumnNameLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoSortDirectionLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoSortDirectionLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSortDirectionLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefFullVO1
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefFullVO1()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefFullVO1");
  }




  /**
   * 
   * Container's getter for XxcsoPvExtractTermSumVO1
   */
  public XxcsoPvExtractTermSumVOImpl getXxcsoPvExtractTermSumVO1()
  {
    return (XxcsoPvExtractTermSumVOImpl)findViewObject("XxcsoPvExtractTermSumVO1");
  }






  /**
   * 
   * Container's getter for XxcsoEnableColumnSumVO1
   */
  public XxcsoEnableColumnSumVOImpl getXxcsoEnableColumnSumVO1()
  {
    return (XxcsoEnableColumnSumVOImpl)findViewObject("XxcsoEnableColumnSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoWhere310LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere310LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere310LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere320LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere320LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere320LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere510LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere510LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere510LookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoWhere600LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere600LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere600LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere610LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere610LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere610LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere660LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere660LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere660LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere670LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere670LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere670LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere730LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere730LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere730LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere740LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere740LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere740LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere770LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere770LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere770LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere780LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere780LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere780LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoAndOrLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoAndOrLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAndOrLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere060LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere060LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere060LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere070LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere070LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere070LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere150LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere150LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere150LookupVO");
  }


  /**
   * 
   * Container's getter for XxcsoWhere080LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere080LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere080LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere300LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere300LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere300LookupVO");
  }



  /**
   * 
   * Container's getter for XxcsoPvDefFullCopyVO
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefFullCopyVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnFullCopyVO
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnFullCopyVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnFullCopyVO
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnFullCopyVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnFullCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermFullCopyVO
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermFullCopyVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermFullCopyVO");
  }




  /**
   * 
   * Container's getter for XxcsoPvDefCopyVO
   */
  public XxcsoPvDefFullVOImpl getXxcsoPvDefCopyVO()
  {
    return (XxcsoPvDefFullVOImpl)findViewObject("XxcsoPvDefCopyVO");
  }






  /**
   * 
   * Container's getter for XxcsoDispayColumnInitVO1
   */
  public XxcsoDispayColumnInitVOImpl getXxcsoDispayColumnInitVO1()
  {
    return (XxcsoDispayColumnInitVOImpl)findViewObject("XxcsoDispayColumnInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoDisplayColumnSumVO1
   */
  public XxcsoDisplayColumnSumVOImpl getXxcsoDisplayColumnSumVO1()
  {
    return (XxcsoDisplayColumnSumVOImpl)findViewObject("XxcsoDisplayColumnSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnFullVO1
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnFullVO1()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermFullVO1
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermFullVO1()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnFullVO1
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnFullVO1()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoPvSortColumnCopyVO
   */
  public XxcsoPvSortColumnFullVOImpl getXxcsoPvSortColumnCopyVO()
  {
    return (XxcsoPvSortColumnFullVOImpl)findViewObject("XxcsoPvSortColumnCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractTermCopyVO
   */
  public XxcsoPvExtractTermFullVOImpl getXxcsoPvExtractTermCopyVO()
  {
    return (XxcsoPvExtractTermFullVOImpl)findViewObject("XxcsoPvExtractTermCopyVO");
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
   * Container's getter for XxcsoPvDefExtractTermVL1
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL1");
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
   * Container's getter for XxcsoPvDefSortColumnVL2
   */
  public ViewLinkImpl getXxcsoPvDefSortColumnVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefSortColumnVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefExtractTermVL2
   */
  public ViewLinkImpl getXxcsoPvDefExtractTermVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefExtractTermVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvDefUpdDfltFlgVO
   */
  public XxcsoPvDefUpdDfltFlgVOImpl getXxcsoPvDefUpdDfltFlgVO()
  {
    return (XxcsoPvDefUpdDfltFlgVOImpl)findViewObject("XxcsoPvDefUpdDfltFlgVO");
  }

  /**
   * 
   * Container's getter for XxcsoPvExtractDispInitVO
   */
  public XxcsoPvExtractDispInitVOImpl getXxcsoPvExtractDispInitVO()
  {
    return (XxcsoPvExtractDispInitVOImpl)findViewObject("XxcsoPvExtractDispInitVO");
  }


  /**
   * 
   * Container's getter for XxcsoWhere620LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere620LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere620LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere220LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere220LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere220LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere550LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere550LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere550LookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoWhere560LookupVO
   */
  public XxcsoConsciousLookupListVOImpl getXxcsoWhere560LookupVO()
  {
    return (XxcsoConsciousLookupListVOImpl)findViewObject("XxcsoWhere560LookupVO");
  }


  /**
   * 
   * Container's getter for XxcsoPvDefViewColumnVL2
   */
  public ViewLinkImpl getXxcsoPvDefViewColumnVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoPvDefViewColumnVL2");
  }

  /**
   * 
   * Container's getter for XxcsoPvViewColumnCopyVO
   */
  public XxcsoPvViewColumnFullVOImpl getXxcsoPvViewColumnCopyVO()
  {
    return (XxcsoPvViewColumnFullVOImpl)findViewObject("XxcsoPvViewColumnCopyVO");
  }

  /**
   * 
   * Container's getter for XxcsoVendorTypeListVO1
   */
  public XxcsoVendorTypeListVOImpl getXxcsoVendorTypeListVO1()
  {
    return (XxcsoVendorTypeListVOImpl)findViewObject("XxcsoVendorTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoWhere790LookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoWhere790LookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoWhere790LookupVO");
  }


}